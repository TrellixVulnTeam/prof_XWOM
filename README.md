prof
====

### An useful program to upload your work on PROF

PROF is where students from computer science of LILLE1 should upload their work. 

Get the newest version on http://github.com/calve/prof

prof is still under devel, it may crash, loose your files, eat your goat.
Always check your file is actually send on the remote server.


## REQUIREMENTS :
 * An ocaml compiler
 * ocaml-findlib : http://projects.camlcity.org/projects/findlib.html
 * ocurl (on ocaml static bind to libcurl) : http://repo.or.cz/w/ocurl.git
 * libcurl


You need to install ocurl (an ocaml bindings to libcurl) on your system.

    git clone http://repo.or.cz/r/ocurl.git
    cd ocurl
    ./configure
    make
    sudo make install

If it fails, please check that libcurl is effectively installed on your system, but it is already there in most cases.

## DOWNLOAD & COMPILE

To download latests source and compile

    git clone https://github.com/calve/prof.git
    cd prof
    make
    ./prof

## UPDATE

To get the last version

    cd prof
    git pull
    make

## USAGE

   * 'prof'  will let you list and delete your TPs after choosing an UE.
   * 'prof --sorted' will list every TPs found, and print them sorted by deadline
   * 'prof archive.tar.gz' will upload archive to the place you will specifie

    ./prof [archive.tar.gz|--sorted]

archive.tar.gz is necessary if you want to upload a file

## CHANGELOG

 - Fix : Date comparaison
 - Added argument --sorted to list all TPs sorted by time. Still experimental
 - QuickFix : Clear buffer containing downloaded pages before getting TP list 
 - TPs contains their UE
 - TPs contains their deadline. Maybe in a future we could sort TP by deadline
 - TPs and UEs numbers are now from 0 to n, and not the actual id on the server	    
 - raise exception when procedures fail 
 - upload a file
 - delete a remote file
 - retrieve TP list
 - connect to the prof website, get cookie, log and retrieve an UE list

## TODO

  - Improve ui and cli

## CONTACT

    calvinh34 at gmail

Bugs, patches and suggestions are welcome !

## A LAST WORD
If nothing work, or if you just want an easy sh script, you may find one in legacy/prof.sh that nearly do the same thing.