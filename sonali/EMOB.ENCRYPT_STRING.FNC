CREATE OR REPLACE FUNCTION EMOB.encrypt_string (p_string VARCHAR2)
RETURN RAW AS
   l_key        VARCHAR2 (2000) := '1234567890999899';
   l_mod NUMBER
         :=   dbms_crypto.encrypt_aes128
            + dbms_crypto.chain_cbc
            + dbms_crypto.pad_pkcs5;
   l_encrypted_raw        RAW (2000);
   l_return RAW (2000);
BEGIN
   l_encrypted_raw :=
      dbms_crypto.encrypt (utl_i18n.string_to_raw (p_string, 'AL32UTF8'),
                           l_mod,
                           utl_i18n.string_to_raw (l_key, 'AL32UTF8'));
   
     dbms_output.put_line ('Encrypted=' || l_encrypted_raw);
     
      RETURN l_encrypted_raw;
END encrypt_string;
/
