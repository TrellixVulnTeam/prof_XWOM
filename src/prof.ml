(*
 * prof.ml
 * A simple cli to libprof
 * User will be prompted for login and password,
 * then for an UE and a TP, and finally, if she/he want
 * to upload the work she/he did, or delete a previsouly
 * send files.
 * 
 * Path to file to upload should be given as the one and only argument to prof 
 *
 * Copyright © 2013 AdB <calvinh34@gmail.com>
 * This work is free. You can redistribute it and/or modify it under the
 * terms of the Do What The Fuck You Want To Public License, Version 2,
 * as published by Sam Hocevar. See the COPYING file for more details.
 *)

let print_ue_list list =
  let rec print list n = 
    match list with
    | [] -> ()
    | ue::_ -> (
      Printf.printf "%d : %s\n" n (Libprof.get_UE_title ue);
      print (List.tl list) (n+1);
    )
  in
  (* Use previously defined function starting with n=0*)
  print list 0
    
let rec print_tp_list list =
  let rec print list n = 
    match list with
    | [] -> ()
    | tp::_ -> ( 
      Printf.printf "%d : %s->%s (%s) [%s] \n" 
	n
	(Libprof.get_UE_title (Libprof.get_TP_ue tp))
	(Libprof.get_TP_title tp)
	(match Libprof.get_TP_status tp with 
	 | true -> "Ouvert" 
	 | _ -> "Ferme")
	(Date.string (Libprof.get_TP_date tp));
      print (List.tl list) (n+1);
    )
  in
  (* Use previously defined function starting with n=0*)
  print list 0

let ask_password s =
  print_string s;
  flush stdout;

  (* We tell the shell to not ouput what the user types *)
  let exit_code = Sys.command "stty -echo" in
  if (exit_code <> 0) then
    failwith "Ask_password error with stty";

  let password = input_line stdin in
  print_newline ();
  (* We turn echo back on *)
  let exit_code = Sys.command "stty echo" in
  if (exit_code <> 0) then
    failwith "Ask_password error with stty"
  else
    password


let ask s = 
  print_string s;
  flush stdout;
  input_line stdin

let upload connection tp =
  (* check arguments *)
  if Array.length Sys.argv != 2 then
    (
      print_string  "usage : prof archive.tar.gz\n No argument found, exciting, nothing done\n";
      failwith "Missing argument"
    )
  else
    Libprof.upload connection tp Sys.argv.(1)

let retrieve_all connection ue_list = 
  let rec retrieve_all connection ue_list = 
    match ue_list with
    | [] -> [] ;
    | ue::list -> ( let tp_list = Libprof.get_TP_list connection ue
		    in
		    tp_list@(retrieve_all connection list)
    )
  in
  retrieve_all connection ue_list

let sorted tp_list =
  let compare tp1 tp2 =
    Date.compare (Libprof.get_TP_date tp1) (Libprof.get_TP_date tp2)
  in
  List.sort compare tp_list

let loop connection =
  let continue = ref true in 
  let ue_list = Libprof.get_UE_list connection in
      
  while !continue do
    print_ue_list ue_list;
    (* Which tp do you want ?
     *)
    let ue_id = int_of_string (ask "ue # ? \n> ") in
    let ue = (List.nth ue_list ue_id) in
    let tp_list = Libprof.get_TP_list connection ue in
    print_newline ();
    print_tp_list tp_list;
    
    (*
     * We should now ask what does my user want to do
     * We suggest to type a lettre from 'u' or 'd', 
     * respectively to upload or delete on a TP
     * Then we add a digit corresponding to the TP where
     * we want the action to be done
     * If the user just hit RETURN, we will upload to TP 0
     *)
    let user_respond = (ask "[u|d|b|q] tp id ? (u to upload a file, d to delete a file, b to go back, q to quit) \n[u0] ") in
    let what_we_want = Str.regexp"\\(u\\|d\\)\\([0-9]+\\)" in

    match user_respond with 
    | "" -> upload connection (List.nth tp_list 0)
    | "q" -> continue := false;
    | "b" -> ();    
    | _ ->      
      if Str.string_match what_we_want user_respond 0 then
	( 
	  (* We will try to read from user input *)
	  let tp_id = int_of_string (Str.matched_group 2 user_respond) in
	  let action = Str.matched_group 1 user_respond in
	  let real_id = List.nth tp_list tp_id in
	  match action with
	  | "u" -> upload connection real_id;
	  | "d" -> Libprof.delete connection real_id;
	  | _ -> print_string "Invalid entry\n";
	);
  done

let _ =
  
  begin
      (*
       *Retriving login and password from user input, then connect to prof
       *)
    let c = Libprof.init_connection () in
    let login = ask "login ? " in
    let continue = ref true in
    while !continue do
      let password = ask_password "password (hidden input) ? " in
      print_newline ();
      try
        Libprof.log c login password;
	continue := false
      with
      | Failure s -> (
	print_string "Incorrect password\n"
      );
    done;
    
    
      (* By default, print sorted by deadlines list *)
    if (Array.length Sys.argv = 1 || Sys.argv.(1) = "--sorted") then
      let ue_list = Libprof.get_UE_list c in
      let all = sorted (retrieve_all c ue_list) in
      print_tp_list all
    else 
      loop c
  end;
  Curl.global_cleanup ()
    
