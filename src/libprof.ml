let baseURL = "https://prof.fil.univ-lille1.fr/";;
let cookieFilePath = "";; (*Just to load cookie engine*)

(*
 * Inspired from ocurl.ml, an examples files provided in ocurl
 *)

type t = (Curl.t * Buffer.t)
type ue = UE of int*string
type tp = TP of int*string*bool*Date.t

(*
 * Write some datas * Buffer.t -> string -> int
 *)
let writer accum data =
  Buffer.add_string accum data;
  String.length data
    
(*
 * Show some datas as string
 *)
let showContent content =
  Printf.printf "%s" (Buffer.contents content);
  flush stdout
    
let showInfo connection =
  Printf.printf "Time: %f\nURL: %s\nResponse: %d"
    (Curl.get_totaltime connection)
    (Curl.get_effectiveurl connection)
    (Curl.get_responsecode connection)

let get_UE_id ue =
  match ue with
    UE (id,title) -> id

let get_UE_title ue =
  match ue with
    UE (id,title) -> title

let get_TP_id tp =
  match tp with
    TP (id,title,status,date) -> id

let get_TP_title tp =
  match tp with
    TP (id,title,status,date) -> title

let get_TP_status tp =
  match tp with
    TP (id,title,status,date) -> status

let get_TP_date tp =
  match tp with
    TP (id,title,status,date) -> date
    
let init_connection () =
  Curl.global_init Curl.CURLINIT_GLOBALALL;
 
  let result = Buffer.create 16384 in
  let connection = Curl.init() in
  Curl.set_verbose connection false;
  Curl.set_writefunction connection (writer result);
  (connection,result)
;; 


(* Get a page
 * Get ressources specified at url using connection, putting output in result
 *)

let fetch connection url =
  Printf.printf "Retriving %s ...\n" (url);
  flush stdout;
  Curl.set_url connection url;
  Curl.perform connection;
  Curl.set_post connection false

(* fetch cookies
 * We'll need to get the cookies before doing anything ....
 *)
let getCookies c =
  let connection = fst c in
  Curl.set_cookiejar connection cookieFilePath;
  fetch connection (baseURL^"index.php")

(*
 * Log l'utilisateur
 *)  
let log c login password =
  getCookies c ;
  let connection = fst c in
  Curl.set_post connection true;
  Curl.set_cookiefile connection cookieFilePath;
  
  (* On crée la liste de ce qu'on passera par FORM *)
  let loginOption = Curl.CURLFORM_CONTENT("login",login,Curl.CONTENTTYPE "text/html") in
  let passwdOption = Curl.CURLFORM_CONTENT("passwd",password,Curl.CONTENTTYPE "text/html") in (** TODO -- encoder l'url*)
  let validerOption = Curl.CURLFORM_CONTENT("++O+K++","Valider",Curl.CONTENTTYPE "text/html") in
  
  (* On donne tout a manger à Curl *)
  Curl.set_httppost connection [loginOption;passwdOption;validerOption];
  
  fetch connection (baseURL^"login.php");
  Curl.set_cookiefile connection cookieFilePath;
      (*On vérifie le code de retour.*)
  if Curl.get_responsecode connection != 302 then
    failwith "Incorrect Login/Password";
;;

let get_UE_list c =
  (* Une fonction interne qui parse la page HTML de choix du projet, 
   * et qui renvoie une liste de couple (id,intitulé)
   *)
  let parse_page page = 
    (*On stocke la liste des UE dans la liste tmp*)
    let tmp = ref [] in 
    (*
     * regexp est une expression régulière pour attraper ce genre de lignes :
     * VALUE="63">Pratique du C, TP</OPTION>
     *)
    let regexp = Str.regexp "VALUE.*OPTION" in
    (* Un simple compteur *)
    let i = ref 0 in
    
    (* On initialise le compteur avec la première occurence trouvée *)
    i := Str.search_forward regexp page !i;
    while (Str.string_match regexp page !i) do
      (*On récupère la chaine trouvée par l'expression régulière*)
      let string = (Str.matched_string page) in
      
      (* On a récupérer ce genre de ligne :
       * VALUE="63">Pratique du C, TP</OPTION
       * Essayons maintenant d'en faire quelque chose du genre 
       * (63*"Pratique du C, TP")
       *)
      let groupe_regexp = Str.regexp ".*\"\\([0-9]+\\)\">\\(.*\\)</OPTION" in
      if Str.string_match groupe_regexp string 0 then
	(
	  let id = int_of_string (Str.matched_group 1 string) in
	  let intitule = Str.matched_group 2 string in
	  
	  tmp := (UE (id,intitule))::!tmp; 
	  (* On prépare le prochain tour, on regarde s'il reste une ligne trouvée par l'expression *)
	  try
	    i := Str.search_forward regexp page (!i+1);
	  with 
	  | Not_found -> (
	    i:= String.length page;
	  );  
	);
    done;
    !tmp;
  in

  let connection = fst c in
  Curl.set_post connection false;
  fetch connection (baseURL^"select_projet.php");
  let page = Buffer.contents (snd c) in
  try
    parse_page page
  with 
  | Not_found -> failwith "get_UE_list failed"
;;

let get_TP_list c ue =
  let parse_page page =
    let tmp = ref [] in
    (*
     * regexp est une expression régulière pour attraper ce genre de lignes :
     * href="javascript:popup('popup.php?id_echeance=140')">Afficheurs avec IHM</a></td>
     *)

    (*tdg stand for Two Digit Group*)
    let tdg = "\\([0-9][0-9]\\)" in
    let date_line = ".*"^tdg^"/"^tdg^"/"^tdg^"-"^tdg^":"^tdg^".*\n" in

    (* Each line, in order *)
    let lines = [".*echeance=\\([0-9]+\\)\')\">\\(.*\\)</a></td>\n";
		 ".*\n";
		 date_line; (*Closing date*)
		 ".*center>\\(Ouvert\\|Ferm.*\\)</td>.*";]
    in
    let regexp = Str.regexp (String.concat "" lines) in
    (* Un simple compteur *)
    let i = ref 0 in
    
    (* On initialise le compteur avec la première occurence trouvée *)
    i := Str.search_forward regexp page !i;
    while (Str.string_match regexp page !i) do
      (*On récupère la chaine trouvée par l'expression régulière*)
      let id = int_of_string (Str.matched_group 1 page) in
      let intitule = Str.matched_group 2 page in
      let date = (
	let day = int_of_string (Str.matched_group 3 page) in
	let month = int_of_string (Str.matched_group 4 page) in
	let year = int_of_string (Str.matched_group 5 page) in
	let hour = int_of_string (Str.matched_group 6 page) in
	let minute = int_of_string (Str.matched_group 7 page) in
	Date.date year month day hour minute
      ) 
      in
      print_string (Date.string date);
      let etat = match Str.matched_group 3 page
	with
	| "Ouvert" -> true 
	| _ -> false
      in

      
      tmp := (TP (id,intitule,etat,date))::!tmp; 

      (* On prépare le prochain tour, on regarde s'il reste une ligne trouvée par l'expression *)
      try
	i := Str.search_forward regexp page (!i+(String.length (Str.matched_string page)));
      with 
      | Not_found -> (
	i:= String.length page;
      );
    done;
    !tmp;    
  in

  let connection = fst c in
  let ueOption = Curl.CURLFORM_CONTENT(
    "id_projet",
    string_of_int (get_UE_id ue),
    Curl.CONTENTTYPE "text/html"
  ) in
  Curl.set_post connection true;
  Curl.set_httppost connection [ueOption];
  fetch connection (baseURL^"main.php");
  let page = Buffer.contents (snd c) in
  try
  parse_page page
  with 
  | Not_found -> failwith "get_TP_list"


(*Upload file as the tp_id using c (curl connection)*)
(*Just a skeleton at that time*)
let upload c tp file =
  let parse_page page =
    let regexp = Str.regexp ".*Le fichier .* est bien enregistr*" in
    (* Un simple compteur *)
    let i = ref 0 in
    
    (* On initialise le compteur avec la première occurence trouvée *)
    try 
      i := Str.search_forward regexp page !i;
    with
    | Not_found -> failwith "upload failed"    
  in

  let connection = fst c in
  fetch connection (baseURL^"upload.php?id="^(string_of_int (get_TP_id tp)));

  Curl.set_followlocation connection true;
  Curl.set_post connection true;

  let curl_file_option = Curl.CURLFORM_FILE("fichier1",file,Curl.CONTENTTYPE "application/x-tar") in
  Curl.set_maxfilesize connection (Int32.of_int 1000000);
  Curl.set_httppost connection [curl_file_option];
  fetch connection (baseURL^"upload2.php");
  
  (*On vérifie que le page renvoyé nous confirme la réussite de l'upload*)
  parse_page (Buffer.contents (snd c));
;;

(* Delete the file associated with tp_id on the prof server *)
let delete c tp_id =
  let parse_page page =
    let regexp = Str.regexp ".*Fichier effac.*" in
    (* Un simple compteur *)
    let i = ref 0 in
    
    (* On initialise le compteur avec la première occurence trouvée *)
    try 
      i := Str.search_forward regexp page !i;
    with
    | Not_found -> failwith "delete failed"    
  in

  let connection = fst c in
  (*Yep, we actualy need to do it twice*)
  fetch connection (baseURL^"delete.php?&id="^(string_of_int tp_id));
  fetch connection (baseURL^"delete.php?action=delete&id="^(string_of_int tp_id));
  parse_page (Buffer.contents (snd c)); 
  (*We should verify that delete was ok ! *)
;;


