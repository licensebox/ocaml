exception Error of string
type client
type callbacks = {on_sign_in:(string -> string -> unit) option;clock:(unit -> float) option;machine_binding:(unit -> string) option;cancelled:(unit -> bool) option}
val default_callbacks:callbacks
val create: ?version:string -> ?server:string -> ?directory:string -> ?ca_bundle:string -> ?callbacks:callbacks -> product:string -> keys:(string*string) list -> unit -> client
val close:client -> unit
val with_client:client -> (client -> 'a) -> 'a
val lease:client -> Yojson.Safe.t
val require:client -> string -> Yojson.Safe.t
val status:client -> Yojson.Safe.t
val sign_in: ?timeout:float -> client -> Yojson.Safe.t
val logout:client -> unit
val modules:client -> Yojson.Safe.t
val requests:client -> Yojson.Safe.t
val request_access: ?note:string -> client -> string list -> Yojson.Safe.t
val access_link:client -> string
val record:client -> command:string -> success:bool -> elapsed:float -> unit
val derive_binding:product:string -> source:string -> string -> string
val native_binding:string -> string
val verify_lease:token:string -> product:string -> keys:(string*string) list -> now:float -> Yojson.Safe.t
