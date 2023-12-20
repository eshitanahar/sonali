CREATE OR REPLACE FUNCTION EMOB.FNC_USER_SLIP (pUserId VARCHAR2)
    RETURN CLOB
IS
    vUserLocation   VARCHAR2 (1024);
    vStyle          CLOB;
    vHtmlText       CLOB;
    vFullSlip       CLOB;
    vCreatedUser    VARCHAR2 (1000);
    vAuthUser       VARCHAR2 (1000);
BEGIN
    vStyle := '
<div id="printableArea">
<head>
    <style>
      body {
        font-family: Arial, sans-serif;
        text-align: center;
      }

      .header {
        display: flex;
        align-items: center;
        justify-content: center;
        margin-bottom: 20px;
      }
      
      .head-img {
        width: 150px;
        height:60px;
        background-size: cover;
      }

      h1 {
        margin: 0;
        font-weight:700;
      }

      table {
        margin: 0 auto 20px;
        border-collapse: collapse;
        width: 100%;
      }
      
      table, th, td {
      border: 1px solid black;
      padding: 10px;
    }
    
      th {
        width: 40%;
        text-align:left;
      }
      td{
      text-align:left;}

      .underline {
        border-bottom: 1px solid black;
      }

      .main-div {
        display: flex;
      }

      .main-div {
        display: flex;
      }

      .Signature-div {
        display: flex;
        width:100%;
        padding-left: 10%;
        padding-top:10%;
        
      }
      
     .watermark {
      position: absolute;
      top: -25%;
      left: 0;
      width: 100%;
      height: 100%;
      z-index: .3; 
      opacity: 0.2; 
      pointer-events: none; 
      background-image: url(''/si/emob/icon/New_Logo.png'');
      background-repeat: no-repeat;
      background-position: center;
      background-size: 300px 100px;
    }
    </style>
    <script>
    function printDiv(divName) {
     var printContents = document.getElementById(divName).innerHTML;
     var originalContents = document.body.innerHTML;

     document.body.innerHTML = printContents;

     window.print();

     document.body.innerHTML = originalContents;
        }
    </script>
  </head>';

    FOR I
        IN (SELECT USER_CODE
                       USER_LOGIN_ID,
                   USER_ID
                       USER_ID,
                   USER_NAME
                       USER_NAME,
                   TYPE_DESC
                       ROLE_TYPE,
                   A.USER_TYPE
                       USER_TYPE,
                   TO_CHAR (A.CREATE_DATE, 'DD-MON-YYYY HH:MIPM')
                       AS CREATION_DATE,
                   A.CHECK_DATE
                       AS EFFECT_DATE,
                   AGENT_POINT_ID
                       AS AGENT_POINT_ID,
                   A.MOBILE_NO
                       AS MOBILE_NO,
                   A.NID
                       AS NID,
                   A.CREATE_BY
                       AS CREATED_BY,
                   A.CHECK_BY
                       AS AUTH_BY
              FROM GUMS.MB_USER_MST  A
                   INNER JOIN GUMS.ST_USER_TYPE B
                       ON A.USER_TYPE = B.USER_TYPE
             WHERE UPPER (USER_CODE) = UPPER (pUserId) AND USER_STS != 'N')
    LOOP
        IF I.USER_TYPE IN ('HOA', 'HOU')
        THEN
            vUserLocation := 'Head office,Dhaka';
        ELSIF I.USER_TYPE = 'ROU'
        THEN
            BEGIN
                SELECT DISTINCT
                          a.RO_NAME
                       || '('
                       || a.RO_ADDRESS
                       || ')'
                       || ',GMO: '
                       || (SELECT DISTINCT
                                  GMO_NAME || '(' || GMO_ADDRESS || ')'
                             FROM EMOB.MB_GMO_LIST
                            WHERE GMO_CODE = a.GMO_CODE)
                  INTO vUserLocation
                  FROM EMOB.MB_RO_LIST  a
                       INNER JOIN GUMS.USER_BRANCH b ON a.RO_CODE = b.RO_CODE
                 WHERE b.USER_ID = I.USER_ID AND b.ACTIVE_FLAG = 'A';
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    vUserLocation := 'RO Tag is Not Found';
            END;
        ELSIF I.USER_TYPE = 'BOU'
        THEN
            BEGIN
                SELECT DISTINCT    a.BRANCH_NAME
                                || '-'
                                || a.BRANCH_CODE
                                || ',PO: '
                                || (SELECT    RO_NAME
                                           || '('
                                           || RO_ADDRESS
                                           || ')'
                                      FROM EMOB.MB_RO_LIST
                                     WHERE RO_CODE = b.RO_CODE)
                                || ',GMO: '
                                || (SELECT    GMO_NAME
                                           || '('
                                           || GMO_ADDRESS
                                           || ')'
                                      FROM EMOB.MB_GMO_LIST
                                     WHERE GMO_CODE = b.GMO_CODE)    USER_LOCATION
                  INTO vUserLocation
                  FROM EMOB.CBS_BRANCH_LIST  a
                       INNER JOIN GUMS.USER_BRANCH b
                           ON a.BRANCH_CODE = b.BRANCH_CODE
                 WHERE b.USER_ID = I.USER_ID AND b.ACTIVE_FLAG = 'A';
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    vUserLocation := 'BRANCH TAG NOT FOUND';
            END;
        ELSIF I.USER_TYPE IN ('AGO', 'AGN')
        THEN
            BEGIN
                SELECT    POINT_NAME
                       || ' ['
                       || AREA_NAME
                       || '] '
                       || ','
                       || 'Branch: '
                       || (SELECT BRANCH_NAME || '-' || BRANCH_CODE
                             FROM EMOB.CBS_BRANCH_LIST
                            WHERE BRANCH_CODE = a.BRANCH_CODE)
                       || ', PO: '
                       || (SELECT DISTINCT
                                  RO_NAME || '(' || RO_ADDRESS || ')'
                             FROM EMOB.MB_RO_LIST
                            WHERE RO_CODE = a.RO_CODE)
                       || ', GMO: '
                       || (SELECT DISTINCT
                                  GMO_NAME || '(' || GMO_ADDRESS || ')'
                             FROM EMOB.MB_GMO_LIST
                            WHERE GMO_CODE = a.GMO_CODE)
                  INTO vUserLocation
                  FROM EMOB.ST_AGENT_POINT a
                 WHERE     POINT_ID = I.AGENT_POINT_ID
                       AND NVL (STATUS, 'N') = 'A';
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    vUserLocation := 'BRANCH TAG NOT FOUND';
            END;
        END IF;

        BEGIN
            SELECT USER_NAME
              INTO vCreatedUser
              FROM GUMS.MB_USER_MST A
             WHERE UPPER (A.USER_CODE) = UPPER (I.CREATED_BY);

            SELECT USER_NAME
              INTO vAuthUser
              FROM GUMS.MB_USER_MST A
             WHERE UPPER (A.USER_CODE) = UPPER (I.AUTH_BY);
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;

        vHtmlText :=
               '<body>
        <div class="watermark"></div>
        <div class="main-div">
            <div style="width:32%">
                <img class="head-img" src="/si/emob/icon/New_Logo.png"/ width=110px;" alt="Logo">
            </div>
            <div class="header" style="width:50%;">
                <header>
                <h1>Sonali Agent Banking</h1>
                <p>User Creation Report</p>
                </header>
            </div>
            <div style="width:20%"></div>
        </div>
        <table>
        <tbody>
            <tr>
            <th>User Type/Role</th>
            <td>'
            || I.ROLE_TYPE
            || '</td>
            </tr>
            <tr>
            <th>User Location</th>
            <td>'
            || vUserLocation
            || '</td>
            </tr>
            <tr>
            <th>User ID</th>
            <td>'
            || I.USER_LOGIN_ID
            || '</td>
            </tr>
            <tr>
            <th>User Name</th>
            <td>'
            || I.USER_NAME
            || '</td>
            </tr>
            <tr>
            <th>User NID Number</th>
            <td>'
            || I.NID
            || '</td>
            </tr>
            <tr>
            <th>User Mobile No</th>
            <td>'
            || I.MOBILE_NO
            || '</td>
            </tr>
            <tr>
            <th>User Creation Date</th>
            <td>'
            || I.CREATION_DATE
            || '</td>
            </tr>
            <tr>
            <th>User Effect Date</th>
            <td>'
            || I.EFFECT_DATE
            || '</td>
            </tr>
        </tbody>
        </table>
        <div class="Signature-div">
        <div style="width:60%; text-align:left;border-top-color:black;">
            <p> <b style="text-decoration:overline;">User Created By (Sign)</b><br>
                <span>HO User/ Admin ID :&nbsp <b>'
            || I.CREATED_BY
            || '</b></span><br>
                <span>Name :&nbsp'
            || vCreatedUser
            || '</span>
            </p>
        </div>
        <div style="width:40%; text-align:left;border-top-color:black;"><p>
        <b style="text-decoration:overline;">User Authorized By (Sign)</b><br>
                <span>HO Admin ID :<b>&nbsp'
            || I.AUTH_BY
            || '</b></span><br>
                <span>Name :&nbsp'
            || vAuthUser
            || '</span>
            </p>
        </div>
        </div>
    </body>
    </div>';
    END LOOP;

    vFullSlip := vStyle || vHtmlText;
    RETURN vFullSlip;
END;
/
