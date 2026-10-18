exception Error of string
let () = Callback.register_exception "licensebox.error" (Error "")
type client
type callbacks = {on_sign_in:(string -> string -> unit) option;clock:(unit -> float) option;machine_binding:(unit -> string) option;cancelled:(unit -> bool) option}
let default_callbacks={on_sign_in=None;clock=None;machine_binding=None;cancelled=None}
external create_raw : string -> callbacks -> client = "lbML_create"
external close : client -> unit = "lbML_close"
external call_raw : client -> string -> string -> string = "lbML_call"
external derive_raw : string -> string -> string -> string = "lbML_derive"
external native_binding : string -> string = "lbML_native"
external verify_raw : string -> string -> string -> float -> string = "lbML_verify"
let create ?(version="") ?server ?directory ?ca_bundle ?(callbacks=default_callbacks) ~product ~keys () =
 let optional name = function None->[]|Some v->[name,`String v] in
 create_raw (Yojson.Safe.to_string (`Assoc (["product",`String product;"keys",`Assoc(List.map(fun(k,v)->k,`String v)keys);"version",`String version]@optional "server" server@optional "directory" directory@optional "ca_bundle" ca_bundle))) callbacks
let with_client c f=Fun.protect ~finally:(fun()->close c) (fun()->f c)
let call c op args=Yojson.Safe.from_string(call_raw c op (`Assoc args |> Yojson.Safe.to_string))
let lease c=call c "lease" []
let require c name=call c "require" ["module",`String name]
let status c=call c "status" []
let sign_in ?(timeout=0.) c=call c "sign_in" ["timeout",`Float timeout]
let logout c=ignore(call c "logout" [])
let modules c=call c "modules" []
let requests c=call c "requests" []
let request_access ?(note="") c names=call c "request" ["modules",`List(List.map(fun s->`String s)names);"note",`String note]
let access_link c=match call c "access-link" [] with `String s->s|_->raise(Error "protocol_error")
let record c ~command ~success ~elapsed=ignore(call c "record" ["command",`String command;"success",`Bool success;"elapsed",`Float elapsed])
let derive_binding ~product ~source raw=let rec trim n=if n>0&&raw.[n-1]='\000' then trim(n-1) else n in derive_raw product source (String.sub raw 0 (trim(String.length raw)))
let verify_lease ~token ~product ~keys ~now=Yojson.Safe.from_string(verify_raw token product (Yojson.Safe.to_string(`Assoc(List.map(fun(k,v)->k,`String v)keys))) now)
