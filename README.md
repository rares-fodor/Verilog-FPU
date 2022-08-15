Am ales sa implementez impartirea si radicalul in floating point. Desi nu am ales IEEE754,
am folosit dimensiunle precizate in standard pentru segmentele numerelor. 


##Floating Point Division


Arhitectura contine doua module: unul care extrage segmentele din operanzi si prelucreaza
exponentul si mantisa, si altul care efectueaza impartirea intre mantise.


Exponentul se determina scazand din bias diferenta celor doi exponenti de la intrare.


Algoritmul pentru impartirea mantiselor este o forma de Long Division “ca pe hartie”,
numaratorul este shiftat la stanga pana cand devine mai mare sau egal cu numitorul.
Atunci din numarator se scade numitorul si se seteaza bitul din quotient corespunzator iteratiei curente.


Daca rezultatul impartirii incepe cu 0, se efectueaza o shiftare la stanga si se decrementeaza exponentul.
In final se indeparteaza hidden bit-ul si se concateneaza segmentele, formand rezultatul final.


##Floating Point Square Root


Arhitectura este asemanatoare celei pentru impartire. 
(Momentan nu functioneaza modulul pentru extragerea radacinii, de ex pentru o mantisa de forma 11b’10000000000.
Pentru celelalte valori testate pare sa functioneze in regula.)


##Precizari


Valorile default ale parametrilor sunt setate pentru half precision/16bit.


Trebuie sa rescriu modulul pentru impartire, deoarece nu am folosit eficient spatiul. Shiftarile la stanga
se fac in acelasi registru si au nevoie de WIDTH dublu.

Am scris modulele treptat, am revenit si schimbat si rescris anumite bucati, si ar fi bine sa le rescriu
si sa incerc sa imbunatatesc arhitecturile putin, dar nu m-as incadra in deadline. In orice caz, o sa continui sa le imbunatatesc.
Principalele imbunatatiri ar fi la modulele de test si la algoritmii folositi. Vreau sa incerc sa le rezolv cu ceva mai efficient,
dar deocamdata abia functioneaza variantele ineficiente. 


As adauga si verificari de validitate (impartire la zero, radicand negativ, etc.)


