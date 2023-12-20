CREATE OR REPLACE FUNCTION EMOB.ALLOW_TRANSACTION (pAppId     VARCHAR2,
                                                   pPageId    VARCHAR2)
   RETURN BOOLEAN
IS
----Changed---Miaze12/18/2023002000asdaasfdffeshita22------
   vCurrentHr          VARCHAR2 (2);
   vAllowTransaction   VARCHAR2 (1);
   vCurrentMinute      VARCHAR2 (2);
   vCurrentAm          VARCHAR2 (2);
   vTranStatHr         VARCHAR2 (2);
   vTranStatMin        VARCHAR2 (2);
   vTranStatAM         VARCHAR2 (2);
   vTranEndHr          VARCHAR2 (2);
   vTranEndMin         VARCHAR2 (2);
   vTranEndPM          VARCHAR2 (2);
   vTran               VARCHAR2 (1);
   vTranStatTime       NUMBER;
   vTranEndTime        NUMBER;
   vCurrentTime        NUMBER;
   vHolidayFlag        VARCHAR2 (1);
   vErrorMessage       VARCHAR2 (500);
   vMyException        EXCEPTION;
BEGIN
   vHolidayFlag := 'N';
   vAllowTransaction := 'N';



   BEGIN
      SELECT NVL (RESTRICT_TRAN_HOUR, 'N')
        INTO vTran
        FROM GUMS.SYMENTRE
       WHERE PAGEID = pPageId AND APP_CODE = pAppId;
   EXCEPTION
      WHEN OTHERS
      THEN
         NULL;
   --vErrorMessage := 'Transaction Flag Finding Problem';
   --RAISE vMyException;
   END;

   IF vTran = 'Y'
   THEN
      BEGIN
         SELECT NVL (ACTIVE_FLAG, 'N')
           INTO vHolidayFlag
           FROM EMOB.MB_HOLIDAY_LIST
          WHERE HOLIDAY_DATE = TRUNC (SYSDATE);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            vHolidayFlag := 'N';
         --vAllowTransaction := 'Y';
         WHEN OTHERS
         THEN
            vErrorMessage := 'Holiday Finding Problem';
            RAISE vMyException;
      END;

      --RAISE_APPLICATION_ERROR(-20010,vHolidayFlag);
      IF vHolidayFlag = 'Y'
      THEN
         vAllowTransaction := 'N';
         vErrorMessage := 'Transaction Not Allow For Holiday';
         RAISE vMyException;
      END IF;

      BEGIN
         SELECT DECODE (TO_CHAR (SYSDATE, 'HH'),
                        12, 0,
                        TO_CHAR (SYSDATE, 'HH')),
                TO_CHAR (SYSDATE, 'MI'),
                TO_CHAR (SYSDATE, 'AM')
           INTO vCurrentHr, vCurrentMinute, vCurrentAm
           FROM DUAL;
      EXCEPTION
         WHEN OTHERS
         THEN
            vErrorMessage :=
               'Current DB system Time Finding Problem. - ' || SQLERRM;
            RAISE vMyException;
      END;



      IF UPPER (vCurrentAm) = 'AM'
      THEN
         vCurrentTime :=
            TO_NUMBER (vCurrentHr) * 3600 + TO_NUMBER (vCurrentMinute) * 60;
      ELSIF UPPER (vCurrentAm) = 'PM'
      THEN
         vCurrentTime :=
              TO_NUMBER (vCurrentHr + 12) * 3600
            + TO_NUMBER (vCurrentMinute) * 60;
      END IF;


      BEGIN
         BEGIN
            SELECT TranStatHr,
                   TranStatMin,
                   TranStatAM,
                   TranEndHr,
                   TranEndMin,
                   TranEndPM
              INTO vTranStatHr,
                   vTranStatMin,
                   vTranStatAM,
                   vTranEndHr,
                   vTranEndMin,
                   vTranEndPM
              FROM (  SELECT MAX (TRAN_ID),
                             SUBSTR (START_TIME, 1, 2) TranStatHr,
                             SUBSTR (START_TIME, 4, 2) TranStatMin,
                             SUBSTR (START_TIME, 7, 2) TranStatAM,
                             SUBSTR (END_TIME, 1, 2) TranEndHr,
                             SUBSTR (END_TIME, 4, 2) TranEndMin,
                             SUBSTR (END_TIME, 7, 2) TranEndPM,
                             EFFECTIVE_DATE,
                             NVL (
                                LEAD (EFFECTIVE_DATE - 1)
                                   OVER (ORDER BY EFFECTIVE_DATE),
                                TRUNC (SYSDATE) + 10)
                                EXPIRE_DATE
                        FROM EMOB.MB_GLOBAL_TRAN_HOUR
                       WHERE     NVL (ACTIVE_FLAG, 'N') = 'Y'
                             AND EFFECTIVE_DATE <= TRUNC (SYSDATE)
                    GROUP BY (START_TIME, END_TIME, EFFECTIVE_DATE))
             WHERE SYSDATE BETWEEN EFFECTIVE_DATE AND EXPIRE_DATE;
         EXCEPTION
            WHEN OTHERS
            THEN
               vErrorMessage := 'System Global Time Finding Problem.';
               RAISE vMyException;
         END;

         IF UPPER (vTranStatAM) = 'AM'
         THEN
            BEGIN
               SELECT   TO_NUMBER (vTranStatHr) * 3600
                      + TO_NUMBER (vTranStatMin) * 60
                 INTO vTranStatTime
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  vErrorMessage := 'System Global Start Time Setup Problem. ';
                  RAISE vMyException;
            END;
         ELSIF UPPER (vTranStatAM) = 'PM'
         THEN
            BEGIN
               vTranStatTime :=
                    TO_NUMBER (vTranStatHr + 12) * 3600
                  + TO_NUMBER (vTranStatMin) * 60;
            EXCEPTION
               WHEN OTHERS
               THEN
                  vErrorMessage := 'System Global Start Time Setting Problem ';
                  RAISE vMyException;
            END;
         ELSE
            vErrorMessage := 'System Global Start Time Setting Problem...';
            RAISE vMyException;
         END IF;



         IF UPPER (vTranEndPM) = 'AM'
         THEN
            BEGIN
               SELECT   TO_NUMBER (vTranEndHr) * 3600
                      + TO_NUMBER (vTranEndMin) * 60
                 INTO vTranEndTime
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  vErrorMessage := 'System Global End Time Setting Problem. ';
                  RAISE vMyException;
            END;
         ELSIF UPPER (vTranEndPM) = 'PM'
         THEN
            BEGIN
               SELECT   TO_NUMBER (vTranEndHr + 12) * 3600
                      + TO_NUMBER (vTranEndMin) * 60
                 INTO vTranEndTime
                 FROM DUAL;
            EXCEPTION
               WHEN OTHERS
               THEN
                  vErrorMessage := 'System Global End Time Setting Problem. ';
                  RAISE vMyException;
            END;
         ELSE
            vErrorMessage := 'System Global End Time Setting Problem.';
            RAISE vMyException;
         END IF;

         IF vCurrentTime >= vTranStatTime AND vCurrentTime <= vTranEndTime
         THEN
            vAllowTransaction := 'Y';
         ELSE
            vAllowTransaction := 'N';
            vErrorMessage :=
               'You do not have permission to access at this time.';
            RAISE vMyException;
         END IF;
      END;
   END IF;

   RETURN TRUE;
--  <<End_Process>>

EXCEPTION
   WHEN vMyException
   THEN
      RETURN FALSE;
END;
/
