
--check for version 20c
SELECT banner FROM v$version; 
--create PDB for blockchain HOL
CREATE PLUGGABLE DATABASE BC_PDB ADMIN USER admin IDENTIFIED BY password
  FILE_NAME_CONVERT=NONE
  STORAGE UNLIMITED TEMPFILE REUSE;
--check PDB created  
SELECT NAME FROM V$CONTAINERS;
--switch to PBD
ALTER SESSION SET CONTAINER=BC_PDB;
--open PDB RW
ALTER PLUGGABLE DATABASE BC_PDB OPEN READ WRITE FORCE; 
--check you are in right PDB
show con_name;
--Create blockchain table
CREATE BLOCKCHAIN TABLE bank_ledger 
       (bank varchar2(128), 
       EOD_deposit NUMBER) --declare columns 
       NO DROP UNTIL 16 DAYS IDLE --no drop mandatory clause min 16 days or no drop at all
       NO DELETE LOCKED --no delete mandatory clause min 16 days or locked
       HASHING USING "sha2_512" VERSION "v1";
       
--Show all blockchain tables in your PDB:
SELECT * FROM dba_blockchain_tables;

----All columns in blockchain tables (incl service columns):
SELECT * FROM DBA_TAB_COLS 
WHERE TABLE_NAME like 'BANK_LEDGER';

--View all columns (incl service columns) from blockchain tables via View
CREATE OR REPLACE VIEW bank_ledger_all AS
SELECT BANK,EOD_DEPOSIT, --your columns
--service columns:
ORABCTAB_INST_ID$,ORABCTAB_CHAIN_ID$,ORABCTAB_SEQ_NUM$,ORABCTAB_CREATION_TIME$,ORABCTAB_USER_NUMBER$,
ORABCTAB_HASH$,ORABCTAB_SIGNATURE$,ORABCTAB_SIGNATURE_ALG$,ORABCTAB_SIGNATURE_CERT$,ORABCTAB_SPARE$
FROM bank_ledger; --your BC table name
--View all columns (incl service columns):
Select * from bank_ledger_all;

INSERT INTO bank_ledger values ('alpha_bank', 121);
INSERT INTO bank_ledger values ('beta_bank', 323);
INSERT INTO bank_ledger values ('gamma_bank', 343);
INSERT INTO bank_ledger values ('delta_bank', 544);
INSERT INTO bank_ledger values ('epsilon_bank', 234);
COMMIT;
--see result
Select * from bank_ledger;
Select * from bank_ledger_all;

DECLARE
        row_data BLOB;
        row_hash RAW(64);
        computed_hash RAW(64);
        buffer RAW(4000);
        inst_id BINARY_INTEGER;
        chain_id BINARY_INTEGER;
        sequence_no BINARY_INTEGER;
        test INTEGER;
BEGIN
        SELECT ORABCTAB_INST_ID$, ORABCTAB_CHAIN_ID$, ORABCTAB_SEQ_NUM$, ORABCTAB_HASH$ 
        INTO inst_id, chain_id, sequence_no, row_hash 
        FROM BANK_LEDGER
        WHERE ORABCTAB_INST_ID$=1 AND ORABCTAB_CHAIN_ID$=1 AND ORABCTAB_SEQ_NUM$ = 5; --fill in numbers from your view
        -- Get bytes used to calculate row hash in row_data variable
        DBMS_BLOCKCHAIN_TABLE.GET_BYTES_FOR_ROW_HASH('SYS', 'BANK_LEDGER', inst_id, chain_id, sequence_no, 1, row_data);
        -- Calculate hash
        computed_hash := DBMS_CRYPTO.HASH(row_data, DBMS_CRYPTO.HASH_SH512);
        -- Get raw data used for hash calculation  printable from BLOB row_data
        test := DBMS_LOB.GETLENGTH (row_data);
        DBMS_LOB.READ (
                   lob_loc => row_data,
                   amount  => test, 
                   offset  => 1,
                   buffer  =>  buffer);
        --print row_data and hash
        DBMS_OUTPUT.PUT_LINE(buffer);
        DBMS_OUTPUT.PUT_LINE(computed_hash);
END;
/

--Tool to calculate NUMBERS stored codes to human-readable 
DECLARE
m_n     NUMBER; 
BEGIN 
       dbms_stats.convert_raw_value('C20323',m_n); --enter your code here 
       dbms_output.put_line('Result: ' || m_n); 
END; 
/ 
--Tool to calculate VARCHAR stored HEX codes to human-readable ASCii
SELECT utl_raw.cast_to_varchar2(hextoraw('657073696C6F6E5F62616E6B')) AS res --enter your code here
FROM dual;

  