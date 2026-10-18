#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <licensebox_json.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
typedef struct{lb_client*p;value callbacks;int busy,failed;} state;
static void error(const char*code){const value*ex=caml_named_value("licensebox.error");if(ex)caml_raise_with_string(*ex,code);caml_failwith(code);}
static const char*text(value v){if(strlen(String_val(v))!=caml_string_length(v))error("invalid_argument");return String_val(v);}
static value invoke_callback(state*s,int index,value a,value b){value opt=Field(s->callbacks,index);if(Is_long(opt))return Val_unit;value r=index==0?caml_callback2_exn(Field(opt,0),a,b):caml_callback_exn(Field(opt,0),Val_unit);if(Is_exception_result(r)){s->failed=1;return Val_unit;}return r;}
static void signin(void*x,const char*u,const char*c){CAMLparam0();CAMLlocal2(a,b);a=caml_copy_string(u);b=caml_copy_string(c);invoke_callback(x,0,a,b);CAMLreturn0;}
static double clock_cb(void*x){CAMLparam0();CAMLlocal1(v);state*s=x;v=invoke_callback(s,1,Val_unit,Val_unit);double n=Is_block(v)&&Tag_val(v)==Double_tag?Double_val(v):NAN;if(!isfinite(n))s->failed=1;CAMLreturnT(double,isfinite(n)?n:0);}
static int binding(void*x,char*out,size_t cap){CAMLparam0();CAMLlocal1(v);state*s=x;v=invoke_callback(s,2,Val_unit,Val_unit);int ok=Is_block(v)&&Tag_val(v)==String_tag&&caml_string_length(v)<cap&&strlen(String_val(v))==caml_string_length(v);if(ok)memcpy(out,String_val(v),caml_string_length(v)+1);else s->failed=1;CAMLreturnT(int,ok?0:1);}
static int cancel_cb(void*x){CAMLparam0();CAMLlocal1(v);state*s=x;if(s->failed)CAMLreturnT(int,1);if(Is_long(Field(s->callbacks,3)))CAMLreturnT(int,0);v=invoke_callback(s,3,Val_unit,Val_unit);if(v!=Val_true&&v!=Val_false)s->failed=1;CAMLreturnT(int,s->failed||v==Val_true);}
#define State(v) (*(state**)Data_custom_val(v))
static void finalize(value v){state*s=State(v);if(s){lb_client_destroy(s->p);caml_remove_generational_global_root(&s->callbacks);free(s);State(v)=NULL;}}
static struct custom_operations ops={"licensebox.client.v1",finalize,custom_compare_default,custom_hash_default,custom_serialize_default,custom_deserialize_default,custom_compare_ext_default,custom_fixed_length_default};
static state*get(value v){state*s=State(v);if(!s||!s->p)error("closed");if(s->busy)error("invalid_argument");return s;}
static value result(lb_result rc,char*out,state*s){CAMLparam0();CAMLlocal1(v);if(s&&s->failed){lb_free(out);s->failed=0;error("callback_failed");}if(rc){lb_free(out);const char*c=s?lb_error_code(s->p):lb_result_code(rc);if(!c||!strcmp(c,"ok")||rc==LB_INVALID_ARGUMENT)c=lb_result_code(rc);error(c);}if(!out)error("protocol_error");v=caml_copy_string(out);lb_free(out);CAMLreturn(v);}
CAMLprim value lbML_create(value options,value callbacks){CAMLparam2(options,callbacks);CAMLlocal1(v);v=caml_alloc_custom(&ops,sizeof(state*),0,1);State(v)=NULL;state*s=calloc(1,sizeof(*s));if(!s)caml_raise_out_of_memory();s->callbacks=callbacks;caml_register_generational_global_root(&s->callbacks);State(v)=s;lb_callbacks cb={s,Is_long(Field(callbacks,0))?NULL:signin,Is_long(Field(callbacks,1))?NULL:clock_cb,Is_long(Field(callbacks,2))?NULL:binding,cancel_cb};const char*o=text(options);lb_result rc=lb_client_create_json(o,&cb,&s->p);if(rc||s->failed){int failed=s->failed;finalize(v);error(failed?"callback_failed":lb_result_code(rc));}CAMLreturn(v);}
CAMLprim value lbML_close(value v){CAMLparam1(v);state*s=State(v);if(s&&s->busy)error("invalid_argument");finalize(v);CAMLreturn(Val_unit);}
CAMLprim value lbML_call(value v,value op,value args){CAMLparam3(v,op,args);state*s=get(v);const char*o=text(op),*a=text(args);char*out=NULL;s->busy=1;lb_result rc=lb_client_call_json(s->p,o,a,&out);s->busy=0;CAMLreturn(result(rc,out,s));}
CAMLprim value lbML_derive(value product,value source,value raw){CAMLparam3(product,source,raw);char out[128];lb_result rc=lb_derive_binding(text(product),text(source),text(raw),out,sizeof(out));if(rc)error(lb_result_code(rc));CAMLreturn(caml_copy_string(out));}
CAMLprim value lbML_native(value product){CAMLparam1(product);char out[128];lb_result rc=lb_native_binding(text(product),out,sizeof(out));if(rc)error(lb_result_code(rc));CAMLreturn(caml_copy_string(out));}
CAMLprim value lbML_verify(value token,value product,value keys,value now){CAMLparam4(token,product,keys,now);char*out=NULL;lb_result rc=lb_verify_lease_json(text(token),text(product),text(keys),Double_val(now),&out);CAMLreturn(result(rc,out,NULL));}
