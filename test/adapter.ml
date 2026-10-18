open Yojson.Safe.Util
let run r=
 let get k=member k r in let s k=get k |> to_string in let p=s "product" in
 let keys()=get "keys" |> to_assoc |> List.map(fun(k,v)->k,to_string v) in
 let now()=match get "now" with `Int n->float_of_int n|v->to_float v in
 match s "op" with
 | "derive"->`String(Licensebox.derive_binding ~product:p ~source:(s "source") (s "raw_id"))
 | "native"->`String(Licensebox.native_binding p)
 | "verify"->Licensebox.verify_lease ~token:(s "token") ~product:p ~keys:(keys()) ~now:(now())
 | op->let callbacks={Licensebox.default_callbacks with clock=Some now;machine_binding=Some(fun()->try s "binding" with _->"");on_sign_in=Some(fun _ _->())} in
 let ca_bundle=match get "ca_bundle" with `String s->Some s|_->None in
 let c=Licensebox.create ~product:p ~keys:(keys()) ~version:"conformance" ~server:(s "server") ~directory:(s "directory") ?ca_bundle ~callbacks () in
 Licensebox.with_client c (fun c->match op with
 | "lease"->Licensebox.lease c|"require"->Licensebox.require c (try s "module" with _->"core")
 | "repeat"->ignore(Licensebox.require c "core");Licensebox.require c "core"
 | "status"->Licensebox.status c|"sign_in"->Licensebox.sign_in ~timeout:3. c
 | "logout"->Licensebox.logout c;`Null|"modules"->Licensebox.modules c|"requests"->Licensebox.requests c
 | "request"->Licensebox.request_access ~note:"café – test" c ["export"]|"access-link"->`String(Licensebox.access_link c)
 | "record"->Licensebox.record c ~command:"export" ~success:true ~elapsed:0.125;Licensebox.record c ~command:"export" ~success:false ~elapsed:0.025;`Null
 | _->failwith "unknown operation")
let ()=let r=Yojson.Safe.from_channel stdin in let a=try `Assoc["ok",`Bool true;"value",run r] with Licensebox.Error code->`Assoc["ok",`Bool false;"error",`String code] in print_endline(Yojson.Safe.to_string a)
