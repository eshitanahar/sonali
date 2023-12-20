CREATE OR REPLACE FUNCTION EMOB.HEIRARCHY_SETUP (pCode    VARCHAR2,
                                                 pType    VARCHAR2)
    RETURN NUMBER
IS
    vCount         NUMBER;
    vCount1        NUMBER;
    vCount2        NUMBER;
    vMyException   EXCEPTION;
BEGIN
    vCount := 0;
    vCount1 := 0;
    vCount2 := 0;

    IF (pType = 'GMO') AND pCode IS NOT NULL
    THEN
        BEGIN
            BEGIN
                SELECT COUNT (*)
                  INTO vCount
                  FROM Emob.MB_CUSTOMER_MST
                 WHERE     GMO_CODE = pCode
                       AND REVIEW_STATUS != 'R'
                       AND CUST_TYPE = 'AGN';
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            BEGIN
                SELECT COUNT (*)
                  INTO vCount1
                  FROM Emob.ST_AGENT_POINT
                 WHERE GMO_CODE = pCode AND STATUS != 'R';
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;
        END;
    ELSIF (pType = 'PO') AND pCode IS NOT NULL
    THEN
        BEGIN
            BEGIN
                SELECT COUNT (*)
                  INTO vCount
                  FROM Emob.MB_CUSTOMER_MST
                 WHERE     RO_CODE = pCode
                       AND REVIEW_STATUS != 'R'
                       AND CUST_TYPE = 'AGN';
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            BEGIN
                SELECT COUNT (*)
                  INTO vCount1
                  FROM Emob.ST_AGENT_POINT
                 WHERE RO_CODE = pCode AND STATUS != 'R';
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;
        END;
    ELSIF (pType = 'BRANCH') AND pCode IS NOT NULL
    THEN
        BEGIN
            BEGIN
                SELECT COUNT (*)
                  INTO vCount
                  FROM Emob.MB_CUSTOMER_MST
                 WHERE     BRANCH_CODE = pCode
                       AND REVIEW_STATUS != 'R'
                       AND CUST_TYPE = 'AGN';
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            BEGIN
                SELECT COUNT (*)
                  INTO vCount1
                  FROM Emob.ST_AGENT_POINT
                 WHERE BRANCH_CODE = pCode AND STATUS != 'R';
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;
        END;
    END IF;

    IF (pType = 'OUTLET') AND pCode IS NOT NULL
    THEN
        BEGIN
            SELECT COUNT (*)
              INTO vCount2
              FROM Emob.ST_AGENT_POINT
             WHERE POINT_CODE = pCode AND STATUS != 'R';
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;
    END IF;

    IF pType IN ('GMO', 'PO', 'BRANCH')
    THEN
        IF vCount = 0 AND vCount1 = 0
        THEN
            RETURN 0;
        ELSE
            RETURN 1;
        END IF;
    END IF;

    IF pType = 'OUTLET'
    THEN
        IF vCount2 = 0
        THEN
            RETURN 0;
        ELSIF vCount2 != 0
        THEN
            RETURN 1;
        END IF;
    END IF;
--  <<End_Process>>

EXCEPTION
    WHEN vMyException
    THEN
        RETURN 1;
END;
/
