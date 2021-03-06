open Filename
open Network_Common

(* Refs for input and output filenames *)
let infname = ref None
let outfname = ref None
let pingall = ref false
let prologue = ref "static/mn_prologue.txt"
let epilogue = ref "static/mn_epilogue.txt"
(* Accepted arguments *)
let arg_spec =
  [
    ("-o",
       Arg.String (fun s -> outfname := Some s ),
       "\tWrite topology to a file")
    ; ("--prologue",
       Arg.String (fun s -> prologue := s),
       "\tPrologue for Mininet scripts")
    ; ("--epilogue",
       Arg.String (fun s -> epilogue := s),
       "\tEpilogue for Mininet scripts")
    ; ("--pingall",
       Arg.Unit (fun () -> pingall := true),
       "\tGenerate Mininet scripts that run pingall on startup")
    ; ("--help",
       Arg.Unit (fun () -> ()),
       "\tDisplay this list of options")
    ; ("-help",
       Arg.Unit (fun () -> ()),
       "\tDisplay this list of options")
]

let usage = Printf.sprintf "usage: %s filename.[dot|gml] -o filename.[dot|py]" Sys.argv.(0)

let to_mininet (t:Net.Topology.t) : string =
  if !pingall then
    Net.Pretty.to_mininet
      ~prologue_file:"static/pingall_prologue.txt"
      ~epilogue_file:"static/pingall_epilogue.txt" t
  else
    Net.Pretty.to_mininet
      ~prologue_file:!prologue
      ~epilogue_file:!epilogue t

(* Check extensions on input or output files and parse/print accordingly *)
let from_extension (fname:string) : Net.Topology.t =
  if check_suffix fname ".dot" then Net.Parse.from_dotfile fname
  else if check_suffix fname ".gml" then Net.Parse.from_gmlfile fname
  else failwith "Cannot parse given file type"

let to_extension fname topo =
  if check_suffix fname ".dot" then Net.Pretty.to_dot topo
  else if check_suffix fname ".gml" then
    failwith "\nWriting to GML format not supported yet\n"
  else if check_suffix fname ".py" then
    to_mininet topo
  else failwith "Cannot write to given file type"


(* Entry point *)
let _ =
  Arg.parse arg_spec (fun fn -> infname := Some fn) usage ;
  let topo = match !infname with
    | None ->   begin Arg.usage arg_spec usage; exit 1 end
    | Some fname -> from_extension fname in
  match !outfname with
    | None -> Printf.printf "\nMininet script: %s\n\n" (to_mininet topo)
    | Some fname ->
      let s = to_extension fname topo in
      output_string (open_out fname) s
