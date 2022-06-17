DROP TABLE Vysetrenie CASCADE CONSTRAINTS;
DROP TABLE Lekar CASCADE CONSTRAINTS;
DROP TABLE Sestra CASCADE CONSTRAINTS;
DROP TABLE Oddelenie CASCADE CONSTRAINTS;
DROP TABLE Hospitalizacia CASCADE CONSTRAINTS;
DROP TABLE Pacient CASCADE CONSTRAINTS;
DROP TABLE Liek CASCADE CONSTRAINTS;
DROP TABLE Detail_uvazku CASCADE CONSTRAINTS;
DROP TABLE Detail_uzivania_lieku CASCADE CONSTRAINTS;

DROP SEQUENCE VYSETRENIE_sequence;

CREATE TABLE Vysetrenie (
ID_vysetrenia  INTEGER,
rodne_cislo CHAR(10) NOT NULL,
ID_lekara INTEGER NOT NULL,
ICPE INTEGER NOT NULL,
datum TIMESTAMP NOT NULL,
vysledok VARCHAR(420)
); 

CREATE TABLE Lekar (
ID_lekara INTEGER,
specifikacia VARCHAR(20),
meno VARCHAR(15) NOT NULL,
priezvisko VARCHAR(15) NOT NULL,
osobne_tel_cislo VARCHAR(10) NOT NULL,
email VARCHAR(50) NOT NULL,
odrobene_hodiny NUMERIC(6,0) DEFAULT 0
); 

CREATE TABLE Sestra (
ID_sestry INTEGER,
ICPE INTEGER NOT NULL,
pozicia VARCHAR(40) NOT NULL,
meno VARCHAR(15) NOT NULL,
priezvisko VARCHAR(15) NOT NULL,
osobne_tel_cislo VARCHAR(10) NOT NULL,
email VARCHAR(50) NOT NULL,
odrobene_hodiny NUMERIC(6,0) DEFAULT 0
); 

CREATE TABLE Oddelenie (
ICPE  INTEGER,
nazov VARCHAR(40) NOT NULL,
kapacita NUMERIC(3,0) NOT NULL,
zaplnenost NUMERIC(3,0) DEFAULT 0 ,
tel_cislo VARCHAR(10) NOT NULL ,
CHECK ( kapacita >= zaplnenost)
); 

CREATE TABLE Hospitalizacia (
ID_hospitalizacie  INTEGER,
ICPE INTEGER NOT NULL,
ID_lekara INTEGER NOT NULL,
rodne_cislo CHAR(10) NOT NULL,
datum TIMESTAMP NOT NULL
); 

CREATE TABLE Pacient (
rodne_cislo CHAR(10),
meno VARCHAR(15) NOT NULL,
priezvisko VARCHAR(15) NOT NULL,
tel_cislo VARCHAR(10) NOT NULL,
obec VARCHAR(40) NOT NULL,
ulica VARCHAR(40) NOT NULL,
cislo_domu NUMERIC(6,0) NOT NULL
); 

CREATE TABLE Liek (
ID_lieku  INTEGER,
nazov VARCHAR(15) NOT NULL,
popis VARCHAR(150) NOT NULL,
vyrobca VARCHAR(50) NOT NULL,
datum_expiracie DATE NOT NULL
); 

CREATE TABLE Detail_uvazku (
ID_lekara INTEGER,
ICPE INTEGER,
dni_ordinacie VARCHAR(50) NOT NULL,
cas_ordinacie VARCHAR(11) NOT NULL,
sluzobne_tel_cislo VARCHAR(10) NOT NULL
); 

CREATE TABLE Detail_uzivania_lieku (
rodne_cislo CHAR(10),
ID_lieku INTEGER,
ID_lekara INTEGER NOT NULL,
pocet_kusov NUMERIC(2,0) NOT NULL,
cas_uzivania VARCHAR(20) NOT NULL,
doba_uzivania NUMERIC(3,0) NOT NULL
); 

ALTER TABLE Vysetrenie ADD CONSTRAINT PK_Vysetrenie PRIMARY KEY (ID_vysetrenia);
ALTER TABLE Lekar ADD CONSTRAINT PK_Lekar PRIMARY KEY (ID_lekara);
ALTER TABLE Sestra ADD CONSTRAINT PK_Sestra PRIMARY KEY (ID_sestry);
ALTER TABLE Oddelenie ADD CONSTRAINT PK_Oddelenie PRIMARY KEY (ICPE);
ALTER TABLE Hospitalizacia ADD CONSTRAINT PK_Hospitalizacia PRIMARY KEY (ID_hospitalizacie);
ALTER TABLE Pacient ADD CONSTRAINT PK_Pacient PRIMARY KEY (rodne_cislo);
ALTER TABLE Liek ADD CONSTRAINT PK_Liek PRIMARY KEY (ID_lieku);
ALTER TABLE Detail_uvazku ADD CONSTRAINT PK_Detail_uvazku PRIMARY KEY (ID_lekara,ICPE);
ALTER TABLE Detail_uzivania_lieku ADD CONSTRAINT PK_Detail_uzivania_lieku PRIMARY KEY (rodne_cislo,ID_lieku);
ALTER TABLE Sestra ADD CONSTRAINT FK_ICPE FOREIGN KEY (ICPE) REFERENCES Oddelenie;
ALTER TABLE Hospitalizacia ADD CONSTRAINT FK_rc FOREIGN KEY (rodne_cislo) REFERENCES Pacient;
ALTER TABLE Hospitalizacia ADD CONSTRAINT FK_ID_lekara FOREIGN KEY (ID_lekara) REFERENCES Lekar;
ALTER TABLE Detail_uvazku ADD CONSTRAINT FK_Detail_uvazku_lekar FOREIGN KEY (ID_lekara) REFERENCES Lekar;
ALTER TABLE Detail_uvazku ADD CONSTRAINT FK_Detail_uvazku_oddelenie FOREIGN KEY (ICPE) REFERENCES Oddelenie;
ALTER TABLE Detail_uzivania_lieku ADD CONSTRAINT FK_Detail_uzivania_lieku_rc FOREIGN KEY (rodne_cislo) REFERENCES Pacient;
ALTER TABLE Detail_uzivania_lieku ADD CONSTRAINT FK_Detail_uzivania_lieku_ID_lieku FOREIGN KEY (ID_lieku) REFERENCES Liek;
ALTER TABLE Vysetrenie ADD CONSTRAINT FK_rc_vys FOREIGN KEY (rodne_cislo) REFERENCES Pacient;
ALTER TABLE Vysetrenie ADD CONSTRAINT FK_ID_lekara_vys FOREIGN KEY (ID_lekara) REFERENCES Lekar;
ALTER TABLE Vysetrenie ADD CONSTRAINT FK_ICPE_vys FOREIGN KEY (ICPE) REFERENCES Oddelenie;
ALTER TABLE Hospitalizacia ADD CONSTRAINT FK_ICPE_hos FOREIGN KEY (ICPE) REFERENCES Oddelenie;


--TRIGGER: Automaticke generovanie primarneho kluca ID_vysetrenia 
CREATE SEQUENCE VYSETRENIE_sequence
    START WITH 1
    INCREMENT BY 1;

CREATE OR REPLACE TRIGGER VYSETRENIE_ID_vys
    BEFORE INSERT ON VYSETRENIE
    FOR EACH ROW
BEGIN
    :NEW.ID_vysetrenia := VYSETRENIE_sequence.nextval;
END;
/

--TRIGGER: kontrola rodneho cislo (10 znakov,spravny format, kontorla platnosti dna v mesiaci) ked je rodne cislo v tabulke PACIENT aktualizovane alebo pridane
CREATE OR REPLACE TRIGGER osoba_rodne_cislo
    BEFORE INSERT OR UPDATE OF rodne_cislo ON PACIENT
    FOR EACH ROW
BEGIN

    IF NOT REGEXP_LIKE(:NEW.rodne_cislo, '^[0-9]{2}((0[1-9]|1[0-2])|(5[1-9]|6[0-2]))((0[1-9])|(1[0-9])|(2[0-9])|(3[0-1]))[0-9]{4}$') THEN
        RAISE_APPLICATION_ERROR(-20001, 'nespravny format rodneho cisla');
    END IF;

    IF NOT ((SUBSTR(:NEW.rodne_cislo, 3, 2) IN ('01', '03', '05', '07', '08', '10', '12', '51', '53', '55', '57', '58', '60', '62') AND CAST(SUBSTR(:NEW.rodne_cislo, 5, 2) AS INT) BETWEEN 1 AND 31)
        OR (SUBSTR(:NEW.rodne_cislo, 3, 2) IN ('04', '06', '09', '11', '54', '56', '59', '61') AND CAST(SUBSTR(:NEW.rodne_cislo, 5, 2) AS INT) BETWEEN 1 AND 30)
        OR (SUBSTR(:NEW.rodne_cislo, 3, 2) IN ('02', '52') AND CAST(SUBSTR(:NEW.rodne_cislo, 5, 2) AS INT) BETWEEN 1 AND 29))
    THEN
        RAISE_APPLICATION_ERROR(-20002, 'neplatny den v mesiaci');
    END IF;

END;
/






INSERT INTO LEKAR
VALUES(10,'chirurg','Pato','Sinek','0913465676','poharmekyho@zbirku.com',140);
INSERT INTO LEKAR
VALUES(12,'endokrinolog','Eva','Mazikova','0918555767','repete@gmail.com',100);
INSERT INTO LEKAR
VALUES(13,'kozny','David','Zidan','0918929687','dvaplusdva@devet.com',10);

INSERT INTO ODDELENIE
VALUES(100,'chirurgicke',100,90,'0902787878');
INSERT INTO ODDELENIE
VALUES(110,'kozne',50,10,'0901989555');
INSERT INTO ODDELENIE
VALUES(120,'endokrynologicke',20,18,'0901732878');

INSERT INTO PACIENT
VALUES('0005124536','Somko','Kotny','0913567876','Konske','Hlavna',5);
INSERT INTO PACIENT
VALUES('3658114245','Zdenka','Studenkova','0918657444','Brno','Nabrezna',12);
INSERT INTO PACIENT
VALUES('0412236667','Karol','Kutil','0912546775','Brno','Kolejni',2);
INSERT INTO PACIENT
VALUES('9203225679','Kozeny','Cloviecik','0912345444','Brno','Kralikaren',208);

INSERT INTO LIEK
VALUES(445566,'Bromhexin','znizuje riziko tazkeho priebehu koronavirusu','Pfizer',TO_DATE('12.10.2025', 'dd.mm.yyyy'));
INSERT INTO LIEK
VALUES(111111,'Paralen','ulavuje od bolesti hlavy','Bazer',TO_DATE('02.01.2022', 'dd.mm.yyyy'));
INSERT INTO LIEK
VALUES(445588,'Ibalgin','zlepsuje travenie','AstraZenecca',TO_DATE('25.06.2028', 'dd.mm.yyyy'));

INSERT INTO DETAIL_UVAZKU
VALUES(13,110,'po-pia','08:00-14:00','0921345878');
INSERT INTO DETAIL_UVAZKU
VALUES(10,100,'po-so','06:00-11:00','0980987789');
INSERT INTO DETAIL_UVAZKU
VALUES(12,120,'po-pia','08:00-17:00','0913476888');

INSERT INTO DETAIL_UZIVANIA_LIEKU
VALUES('0005124536',445566,12,2,'rano,vecer',7);
INSERT INTO DETAIL_UZIVANIA_LIEKU
VALUES('3658114245',111111,10,5,'po jedle',17);
INSERT INTO DETAIL_UZIVANIA_LIEKU
VALUES('0412236667',445588,13,1,'rano',70);


INSERT INTO HOSPITALIZACIA
VALUES(131,100,10,'0005124536',TO_TIMESTAMP('2020-01-01 12:12:00', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO HOSPITALIZACIA
VALUES(132,110,12,'3658114245',TO_TIMESTAMP('2020-12-06 10:10:00', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO HOSPITALIZACIA
VALUES(133,120,13,'0412236667',TO_TIMESTAMP('2021-03-15 06:30:00', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO HOSPITALIZACIA
VALUES(134,120,13,'3658114245',TO_TIMESTAMP('2021-04-14 06:33:00', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO SESTRA
VALUES(20,100,'vrchna sestra','Nora','Mojsejova','0912456387','uznemambrana@zoznam.sk',180);
INSERT INTO SESTRA
VALUES(22,110,'student','Sisa','Sklovska','0913475887','spycegirls@gmail.com',10);
INSERT INTO SESTRA
VALUES(23,120,'zastupca vrchnej sestry','Darina','Rollinsova','0923989777','dara@rolins.com',150);

INSERT INTO VYSETRENIE
VALUES(1,'0005124536',10,100,TO_TIMESTAMP('2020-01-01 12:12:00', 'YYYY-MM-DD HH24:MI:SS'),'fraktura lebky z dovodu hrania PC hier');
INSERT INTO VYSETRENIE
VALUES(13,'3658114245',12,110,TO_TIMESTAMP('2021-12-12 14:30:30', 'YYYY-MM-DD HH24:MI:SS'),'otravenie alkoholom za ucelom prejdenia Dobsinskeho kopca, aby zrobil frajerinu');
INSERT INTO VYSETRENIE
VALUES(12,'0412236667',13,120,TO_TIMESTAMP('2021-02-03 20:15:20', 'YYYY-MM-DD HH24:MI:SS'),'omrzliny na nohach, lebo vonku bola zima a nedal si polievocku');
INSERT INTO VYSETRENIE
VALUES(4,'0412236667',13,120,TO_TIMESTAMP('2021-03-22 10:10:10', 'YYYY-MM-DD HH24:MI:SS'),'kontrola omrzlin na nohach');
INSERT INTO VYSETRENIE
VALUES(5,'9203225679',10,100,TO_TIMESTAMP('2021-01-01 00:15:20', 'YYYY-MM-DD HH24:MI:SS'),'bol sa kupat na Senci, smykol sa na lade a prelomil si chrbticu');
INSERT INTO VYSETRENIE
VALUES(6,'9203225679',10,100,TO_TIMESTAMP('2021-01-10 10:10:10', 'YYYY-MM-DD HH24:MI:SS'),'chrbtica fixed');
INSERT INTO VYSETRENIE
VALUES(7,'3658114245',13,120,TO_TIMESTAMP('2021-11-11 11:11:30', 'YYYY-MM-DD HH24:MI:SS'),'kym napisal interpret, oslepol');
INSERT INTO VYSETRENIE
VALUES(8,'3658114245',10,100,TO_TIMESTAMP('2021-12-11 12:11:30', 'YYYY-MM-DD HH24:MI:SS'),'presla ho vzducholod');

-- Ktory lekari vykonali viac ako jednu hospitalizaciu. ( ID_lekara, meno, priezvisko, pocet hospitalizacii )

SELECT lek.ID_lekara, lek.meno, lek.priezvisko, COUNT(lek.ID_LEKARA) AS POCET_HOSPITALIZACII
FROM HOSPITALIZACIA hos
JOIN LEKAR lek ON lek.ID_lekara = hos.ID_lekara
GROUP BY lek.ID_lekara, lek.meno, lek.priezvisko
HAVING COUNT(lek.ID_lekara) > 1;


-- Ake su oddelenia na ktorych je presne jedna hospitalizacia v marci 2021. (ICPE, nazov oddelenia)

SELECT odd.ICPE, odd.nazov
FROM HOSPITALIZACIA hos
JOIN ODDELENIE odd ON odd.ICPE = hos.ICPE
WHERE hos.datum BETWEEN TO_TIMESTAMP('2021-03-01 00:00:01', 'YYYY-MM-DD HH24:MI:SS') AND TO_TIMESTAMP('2021-03-31 23:59:59', 'YYYY-MM-DD HH24:MI:SS')
GROUP BY odd.ICPE, odd.nazov
HAVING COUNT(hos.ICPE) = 1;

-- ktory pacienti z mesta Brno podstupuju viacero vysetreni u jedneho lekara (rodne_cislo, meno, priezvisko, ulica, ID_lekara)

SELECT pac.rodne_cislo, pac.meno, pac.priezvisko, pac.ulica, lek.ID_lekara
FROM VYSETRENIE vys
JOIN LEKAR lek ON lek.ID_lekara = vys.ID_lekara
JOIN PACIENT pac ON pac.rodne_cislo = vys.rodne_cislo
WHERE pac.obec = 'Brno'
GROUP BY pac.rodne_cislo, pac.meno, pac.priezvisko, pac.ulica, lek.ID_lekara 
HAVING COUNT(pac.rodne_cislo) > 1;


-- Ktory pacienti maju vysetrenia na vsetkych oddeleniach nemocnice. (rodne_cislo, meno, priezvisko)

SELECT pac.rodne_cislo, pac.meno, pac.priezvisko
FROM PACIENT pac
WHERE NOT EXISTS 
    (SELECT * FROM ODDELENIE odd WHERE NOT EXISTS 
        (SELECT * FROM VYSETRENIE vys WHERE vys.rodne_cislo=pac.rodne_cislo AND vys.ICPE=odd.ICPE));

-- Ktory pacienti boli na vyseterni len na oddeleni chirurgie (ICPE, nazov)

SELECT pac.rodne_cislo, pac.meno, pac.priezvisko
FROM PACIENT pac
WHERE pac.rodne_cislo NOT IN
    (SELECT pac.rodne_cislo
    FROM VYSETRENIE vys
    JOIN PACIENT pac ON pac.rodne_cislo = vys.rodne_cislo
    JOIN ODDELENIE odd ON odd.ICPE = vys.ICPE
    WHERE odd.nazov != 'chirurgicke')
AND pac.rodne_cislo IN
    (SELECT pac.rodne_cislo
    FROM VYSETRENIE vys
    JOIN PACIENT pac ON pac.rodne_cislo = vys.rodne_cislo
    JOIN ODDELENIE odd ON odd.ICPE = vys.ICPE
    WHERE odd.nazov = 'chirurgicke');

-- UKAZKA TRIGGER: Automaticke generovanie primarneho kluca ID_vysetrenia bez implicitneho zadania
SELECT * FROM VYSETRENIE;
INSERT INTO VYSETRENIE (rodne_cislo, ID_lekara, ICPE, datum, vysledok)
VALUES('9203225679',10,100,TO_TIMESTAMP('2021-02-18 12:00:00', 'YYYY-MM-DD HH24:MI:SS'),'ohybny ako bic');
SELECT * FROM VYSETRENIE;

-- UKAZKA TRIGGER: kontrola rodneho cislo (10 znakov,spravny format, kontorla platnosti dna v mesiaci) ked je rodne cislo v tabulke PACIENT aktualizovane alebo pridane
INSERT INTO PACIENT (rodne_cislo, meno, priezvisko, tel_cislo, obec, ulica, cislo_domu )
VALUES('0006261234','Janko','Mrkvicka','0912344555','Bratislava','Nabrezna',15);
SELECT * FROM PACIENT;


-- Procedura 1: procedura vypise informacie o danom oddeleni
CREATE OR REPLACE PROCEDURE odd_info ("odd" IN VARCHAR)
AS 
    "icpe_odd" Oddelenie.ICPE%TYPE;
    "pocet_s" NUMBER;
    "pocet_l" NUMBER;
    "pocet_hos" NUMBER;
    "pocet_vys" NUMBER;
BEGIN
    --zistenie ID zadaneho oddelenia
    SELECT "ICPE" INTO "icpe_odd" FROM Oddelenie  WHERE nazov = "odd";
    
    SELECT COUNT(*) INTO "pocet_s" FROM Sestra WHERE ICPE="icpe_odd";
    SELECT COUNT(*) INTO "pocet_l" FROM Detail_uvazku WHERE ICPE="icpe_odd";
    SELECT COUNT(*) INTO "pocet_hos" FROM Hospitalizacia WHERE ICPE="icpe_odd";
    SELECT COUNT(*) INTO "pocet_vys" FROM Vysetrenie WHERE ICPE="icpe_odd";
    
    -- vypis do konzole
    DBMS_OUTPUT.put_line(
		'Informacie o oddeleni:' || "odd" || chr(10) ||
		'Pocet sestier: ' || "pocet_s" || chr(10) ||
		'Pocet lekarov: ' || "pocet_l" || chr(10) ||
		'Pocet hospitalizacii: ' || "pocet_hos" || chr(10) ||
        'Pocet vysetreni: ' || "pocet_vys"
	);
    
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR (-20003, 'Zadane oddelenie nebolo najdene');
    
END;
/

exec odd_info('chirurgicke')

-- Procedura 2: Kolko pacientov uziva dany liek
CREATE OR REPLACE PROCEDURE liek_uzivanie ("liek" IN VARCHAR)
AS 
    "pocet_p" NUMBER;
    "pocet_p_liek" NUMBER;
    "id_liek" Liek.ID_lieku%TYPE;
    "var_id_liek" Liek.ID_lieku%TYPE;
    "pac" Pacient.rodne_cislo%TYPE;
    "var_pac" Pacient.rodne_cislo%TYPE;
    CURSOR "pacienti" IS SELECT rodne_cislo FROM Pacient;
    CURSOR "liek_pac" IS SELECT ID_lieku, rodne_cislo FROM Detail_uzivania_lieku;
BEGIN
    --zistenie id lieku
    SELECT ID_lieku INTO "id_liek" FROM Liek  WHERE nazov = "liek";
    
    SELECT COUNT(*) INTO "pocet_p" FROM Pacient;
    
    "pocet_p_liek" := 0;
    
    OPEN "pacienti";
	LOOP
		FETCH "pacienti" INTO "pac";
        OPEN "liek_pac";
            LOOP
            FETCH "liek_pac" INTO "var_id_liek", "var_pac";
            IF "var_id_liek" = "id_liek" AND "pac" = "var_pac" THEN
                "pocet_p_liek" := "pocet_p_liek" + 1;
                EXIT;
            END IF;
            EXIT WHEN "liek_pac"%NOTFOUND;
        END LOOP;
        CLOSE "liek_pac";
        
		EXIT WHEN "pacienti"%NOTFOUND;

	END LOOP;
	CLOSE "pacienti";
    
    -- vypis do konzole
    DBMS_OUTPUT.put_line(
		'Liek: ' || "liek" || ' uziva ' || "pocet_p_liek" || ' z ' ||
        "pocet_p" || ' pacientov.'
	);
    
    EXCEPTION WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR (-20004, 'Zadany liek nebol najdeny');
END;
/

exec liek_uzivanie('Ibalgin')



-- EXPLAIN PLAN pre dotaz"ktory pacienti z mesta Brno podstupuju viacero vysetreni u jedneho lekara (rodne_cislo, meno, priezvisko, ulica, ID_lekara)" bez indexu
    
    EXPLAIN PLAN FOR
        SELECT pac.rodne_cislo, pac.meno, pac.priezvisko, pac.ulica, lek.ID_lekara
        FROM VYSETRENIE vys
        JOIN LEKAR lek ON lek.ID_lekara = vys.ID_lekara
        JOIN PACIENT pac ON pac.rodne_cislo = vys.rodne_cislo
        WHERE pac.obec = 'Brno'
        GROUP BY pac.rodne_cislo, pac.meno, pac.priezvisko, pac.ulica, lek.ID_lekara 
        HAVING COUNT(pac.rodne_cislo) > 1;
    SELECT PLAN_TABLE_OUTPUT FROM table (dbms_xplan.display());


-- EXPLAIN PLAN pre dotaz "ktory pacienti z mesta Brno podstupuju viacero vysetreni u jedneho lekara (rodne_cislo, meno, priezvisko, ulica, ID_lekara)" s indexom

CREATE INDEX double_index ON VYSETRENIE (ID_LEKARA,RODNE_CISLO);
    EXPLAIN PLAN FOR
        SELECT pac.rodne_cislo, pac.meno, pac.priezvisko, pac.ulica, lek.ID_lekara
        FROM VYSETRENIE vys
        JOIN LEKAR lek ON lek.ID_lekara = vys.ID_lekara
        JOIN PACIENT pac ON pac.rodne_cislo = vys.rodne_cislo
        WHERE pac.obec = 'Brno'
        GROUP BY pac.rodne_cislo, pac.meno, pac.priezvisko, pac.ulica, lek.ID_lekara 
        HAVING COUNT(pac.rodne_cislo) > 1;
    SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());

DROP INDEX double_index;



-- PRISTUPOVE PRAVA k objektom databazy druhemu uzivatelovi

GRANT ALL ON LIEK                   TO xhorni20;
GRANT ALL ON LEKAR                  TO xhorni20;
GRANT ALL ON SESTRA                 TO xhorni20;
GRANT ALL ON VYSETRENIE             TO xhorni20;
GRANT ALL ON ODDELENIE              TO xhorni20;
GRANT ALL ON HOSPITALIZACIA         TO xhorni20;
GRANT ALL ON PACIENT                TO xhorni20;
GRANT ALL ON DETAIL_UVAZKU          TO xhorni20;
GRANT ALL ON DETAIL_UZIVANIA_LIEKU  TO xhorni20;

GRANT EXECUTE ON odd_info TO xhorni20;
GRANT EXECUTE ON liek_uzivanie TO xhorni20;

DROP MATERIALIZED VIEW udaj_o_vysetreni;


--- MATERIALIZOVANY POHLAD na vsetky potrebne udaje o vysetreni

CREATE MATERIALIZED VIEW udaj_o_vysetreni
    NOLOGGING
    CACHE
    BUILD IMMEDIATE
    ENABLE QUERY REWRITE
AS
SELECT vys.ID_vysetrenia, pac.meno, pac.priezvisko, vys.rodne_cislo, vys.ID_lekara , vys.ICPE, vys.datum , vys.vysledok
FROM xbrnaf00.VYSETRENIE vys
JOIN PACIENT pac ON pac.rodne_cislo = vys.rodne_cislo;

GRANT ALL ON udaj_o_vysetreni TO xhorni20; 

SELECT * FROM udaj_o_vysetreni;