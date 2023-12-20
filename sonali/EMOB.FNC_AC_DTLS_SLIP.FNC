CREATE OR REPLACE FUNCTION EMOB.FNC_AC_DTLS_SLIP (
    pAccountNo    VARCHAR2,
    pAppSession   VARCHAR2 DEFAULT NULL)
    RETURN CLOB
IS
    vNomLoop          CLOB;
    vHeader           CLOB;
    vBody             CLOB;
    vNominee          CLOB;
    vHtmlReport       CLOB;
    vPrsAdress        VARCHAR2 (3000);
    vPerAdress        VARCHAR2 (3000);
    vAcNO             VARCHAR2 (1024);
    vAcTitle          VARCHAR2 (1024);
    vCustCode         VARCHAR2 (1024);
    vProductName      VARCHAR2 (1024);
    vActypeName       VARCHAR2 (1024);
    vAcSubTypName     VARCHAR2 (1024);
    vAcHolderName     VARCHAR2 (1024);
    vFatherName       VARCHAR2 (1024);
    vMotherName       VARCHAR2 (1024);
    vSpouseName       VARCHAR2 (1024);
    vTinNo            VARCHAR2 (1024);
    vVinNo            VARCHAR2 (1024);
    vIntroName        VARCHAR2 (1024);
    vIntrAcNo         VARCHAR2 (1024);
    vNidNo            VARCHAR2 (1024);
    vBrcNo            VARCHAR2 (1024);
    vBranchCode       VARCHAR2 (1024);
    vAgentPointName   VARCHAR2 (1024);
    vAc_ID            NUMBER;
    vCustNo           NUMBER;
    vMobileNo         VARCHAR2 (100);
    vMail             VARCHAR2 (500);
    IniUserID         VARCHAR2 (100);
    FinUserId         VARCHAR2 (100);
    IniUserName       VARCHAR2 (100);
    FinUserName       VARCHAR2 (100);
BEGIN
    vHeader := '
    <div id="printableArea">
    <head>
    <style>
        /*.main_table {
            width: 80%;
            margin: 16px 19px 18px 100px;
        }*/
        
        h1,h2,h4,h3,h5,h6{
         font-weight:800;
         }
         
         .center {
            display:block;
            margin-left:auto;
            margin-right:auto;
            }

        .table_2,
        .table_3,
        .table_4,
        .table_5,
        .table_6,
        .table_7,
        .table_8 ,th ,td{
            border: 1px solid #f3ebeb;
            border-collapse: collapse;}
        
          .head_table {
            border: none;
            border-collapse: collapse;}

        .head_table,
        .table_2,
        .table_3,
        .table_4,
        .table_5,
        .table_6,
        .table_7,
        .table_8 {
            width: 100%;
            height: 50px;
            font-size:11px;
        }
        td.bordered,
        th.bordered {
                       border: none; /* Change the border style for cells with class "bordered" */
                   }
            .Signature-div {
        display: flex;
        width:100%;
        padding-left: 1%;
        font-size:11px;
        padding-top:1%;
        
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

    BEGIN
        SELECT A.AC_ID
                   AC_ID,
               A.CUST_NO
                   CUST_NO,
               A.AC_NO
                   ACCOUNT_NO,
               A.AC_TITLE
                   ACCOUNT_TITLE,
               B.CUST_CODE
                   CUSTOMER_ID,
               C.FULL_DESC
                   PRODUCT_NAME,
               C.SHORT_DESC
                   AC_TYPE_NAME,
               (SELECT TYPE_DESC
                  FROM EMOB.MB_ACCOUNT_SUB_TYPE
                 WHERE AC_TYPE = c.SHORT_DESC)
                   AC_SUB_TYPE,
               A.AC_TITLE
                   AC_HOLDER_NAME,
               B.FATHER_NAME
                   FATHER_NAME,
               B.MOTHER_NAME
                   MOTHER_NAME,
               NVL (B.SPOUSE_NAME, 'N/A')
                   SPOUSE_NAME,
               NVL (B.TIN_NO, 'N/A')
                   TIN_NO,
               NVL (B.VIN_NO, 'N/A')
                   VIN_NO,
               E.INTRO_NAME
                   INTRO_NAME,
               E.INTRO_ACCOUNT_NO
                   INTRO_ACCOUNT_NO,
               NVL (B.MOBILE_NO, B.MOBILE_NO2)
                   MOBILE_NO,
               B.MAIL_ID,
               A.INI_CHECK_BY
                   INI_USER_ID,
               A.FIN_CHECK_BY
                   FINAL_USER_ID,
               (SELECT USER_NAME
                  FROM GUMS.MB_USER_MST
                 WHERE UPPER (USER_CODE) = UPPER (A.INI_CHECK_BY))
                   INI_USER_NAME,
               (SELECT USER_NAME
                  FROM GUMS.MB_USER_MST
                 WHERE UPPER (USER_CODE) = UPPER (A.FIN_CHECK_BY))
                   INI_USER_NAME,
               a.BRANCH_CODE,
               (SELECT POINT_NAME || '[ ' || POINT_ID || ' ]'
                  FROM EMOB.ST_AGENT_POINT
                 WHERE POINT_ID = a.POINT_ID)
                   Outlet
          INTO vAc_ID,
               vCustNo,
               vAcNO,
               vAcTitle,
               vCustCode,
               vProductName,
               vActypeName,
               vAcSubTypName,
               vAcHolderName,
               vFatherName,
               vMotherName,
               vSpouseName,
               vTinNo,
               vVinNo,
               vIntroName,
               vIntrAcNo,
               vMobileNo,
               vMail,
               IniUserID,
               FinUserId,
               IniUserName,
               FinUserName,
               vBranchCode,
               vAgentPointName
          FROM EMOB.MB_ACCOUNT_MST  A
               INNER JOIN MB_CUSTOMER_MST B ON A.CUST_NO = B.CUST_NO
               INNER JOIN EMOB.MB_PRODUCT_MST C
                   ON A.AC_TYPE_ID = C.AC_TYPE_ID
               FULL OUTER JOIN EMOB.MB_INTRODUCER_INFO E ON A.AC_ID = E.AC_ID
         WHERE     A.AC_NO = pAccountNo
               AND NVL (C.DEP_NATURE, 'R') = 'R'
               AND NVL (A.AC_STATUS, 'NEW') = 'ACT';
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            RAISE_APPLICATION_ERROR (-20001,
                                     'Customer Details Finding Problem');
        WHEN OTHERS
        THEN
            RAISE_APPLICATION_ERROR (-20001,
                                     'Customer Details query Problem');
    END;

    BEGIN
        FOR I
            IN (SELECT DOCMENT_NO, DOCUMENT_TYPE
                  FROM EMOB.MB_DOCUMENT_MST
                 WHERE     CUST_NO = vCustNo
                       AND DOCUMENT_TYPE IN ('SID', 'NID', 'BRN'))
        LOOP
            IF I.DOCUMENT_TYPE = 'SID' AND I.DOCMENT_NO IS NOT NULL
            THEN
                vNidNo := I.DOCMENT_NO;
            ELSIF I.DOCUMENT_TYPE = 'NID' AND I.DOCMENT_NO IS NOT NULL
            THEN
                vNidNo := I.DOCMENT_NO;
                vBrcNo := 'N/A';
            ELSIF I.DOCUMENT_TYPE = 'BRN' AND I.DOCMENT_NO IS NOT NULL
            THEN
                vBrcNo := I.DOCMENT_NO;
                vNidNo := 'N/A';
            ELSE
                vNidNo := 'N/A';
                vBrcNo := 'N/A';
            END IF;
        END LOOP;
    END;

    --------------Address Details-------
    BEGIN
        FOR I
            IN (SELECT A.ADDRESS_TYPE,
                          (SELECT TYPE_DESC
                             FROM EMOB.ST_ADDRESS_TYPE
                            WHERE     ADDRESS_TYPE = a.ADDRESS_TYPE
                                  AND ADDRESS_TYPE = 'PRS')
                       || '-'
                       || (SELECT DIVISION_CODE || ' - ' || DIVISION_NAME
                             FROM EMOB.DIVISION_INFO
                            WHERE DIVISION_CODE = a.DIV)
                       || '-'
                       || (SELECT DISTRICT_CODE || ' - ' || DISTRICT_NAME
                             FROM EMOB.DISTRICT_INFO
                            WHERE     DIVISION_CODE = a.DIV
                                  AND DISTRICT_CODE = a.DISTRICT_CODE)
                       || '-'
                       || (SELECT UPAZILA_CODE || ' - ' || UPAZILA_NAME
                             FROM EMOB.UPAZILA_INFO
                            WHERE     DISTRICT_CODE = a.DISTRICT_CODE
                                  AND UPAZILA_CODE = a.PS_CODE)
                       || '-'
                       || NVL (
                              (SELECT POST_CODE || ' - ' || SUB_OFFICE
                                 FROM POSTAL_CODE
                                WHERE     DISTRICT_CODE = a.DISTRICT_CODE
                                      AND POST_CODE = a.POST_CODE),
                              POST_CODE)
                       || '-'
                       || ADD_LINE1
                       || '-'
                       || ADD_LINE2    ADDRESS
                  FROM EMOB.MB_ADDRESS_MST   a,
                       EMOB.VW_ALL_ZONE      b,
                       EMOB.ST_ADDRESS_TYPE  c
                 WHERE     A.DISTRICT_CODE = B.DISTRICT_CODE
                       AND A.PS_CODE = B.UPAZILA_CODE
                       AND A.ADDRESS_TYPE = C.ADDRESS_TYPE
                       AND A.ADDRESS_FOR = 'CUS'
                       AND A.REF_NO = vCustNo)
        LOOP
            IF I.ADDRESS_TYPE = 'PRS'
            THEN
                vPrsAdress := I.ADDRESS;
            ELSIF I.ADDRESS_TYPE != 'PRS'
            THEN
                vPerAdress := I.ADDRESS;
            END IF;
        END LOOP;
    END;



    BEGIN
        FOR NOM IN (SELECT ROWNUM                       ROW_NUM,
                           INITCAP (N.NOMINEE_NAME)     NOMINEE_NAME,
                           N.DOB                        DOB,
                           N.NOM_PERCENT                NOM_SHARE,
                           N.DOCMENT_NO                 DOC_NO
                      FROM EMOB.NOMINEE_MST N
                     WHERE N.AC_ID = vAc_id)
        LOOP
            vNomLoop :=
                   '<tr>
                <td style="width: 20px;">&nbsp;'
                || NOM.ROW_NUM
                || '</td>
                <td style="width: 190px;">&nbsp;'
                || NOM.NOMINEE_NAME
                || '</td>
                <td style="width: 190px;">&nbsp;'
                || NOM.DOB
                || '</td>
                <td style="width: 190px;">&nbsp;'
                || NOM.NOM_SHARE
                || '</td>
                <td style="width: 254.75px;">&nbsp;'
                || NOM.DOC_NO
                || '</td>
            </tr>';

            vNominee := vNominee || vNomLoop;
        END LOOP;
    END;

    vBody :=
           '<body>
            <div  class="main_table" >
            <table id="head_table" class="head_table">
            <tbody>
            <tr style="height: 80px;">
                <td class="bordered" style="width: 150px; height:80px;"><img class="center" style="object-fit: cover;"
                        src="/si/emob/icon/New_Logo.png"
                        alt="" width="100" height="100" /></td>
                        
                <td class="bordered" style="width: 602.734px; ">
                <table style="width:100% ;border-collapse:none; border:none;">
                <tr>
                    <td class="bordered"><h2 style="text-align: center; colspan:3;"><u>SONALI BANK PLC</u></h2></td>
                </tr>
                    <tr>
                        <td class="bordered" style="text-align: center;"><b>Branch : &nbsp;</b>'
        || vBranchCode
        || '</td>
                    </tr>
                    <tr>
                        <td class="bordered" style="text-align: center;"><b>Outlet : &nbsp;</b>'
        || vAgentPointName
        || '</td>
                    </tr>   
                </table>
                </td>
                <td class="bordered" style="width: 100px; height: 80px;"><img class="center"
                        src="f?p=105:386:'
        || pAppSession
        || ':'
        || vCustNo
        || '"alt="" width="151" height="151" /></td>
            </tr>
        </tbody>
    </table>
    <table class="table_2" style="height: 49px; ">
        <tbody>
            <tr>
                <td style="width: 1039px;">
                    <h6 style="text-align: center;">Account Details</h6>
                </td>
            </tr>
        </tbody>
    </table>
    <table class="table_3" style="height: 32px;">
        <tbody>
            <tr style="height: 26px;">
                <td style="width: 265px; height: 26px;"><strong>&nbsp;Account Number&nbsp;</strong></td>
                <td style="width: 765.234px; height: 26px;">&nbsp;'
        || vAcNO
        || '</td>
            </tr>
            <tr style="height: 13px;">
                <td style="width: 265px; height: 13px;"><strong>&nbsp;Client/Customer ID</strong></td>
                <td style="width: 765.234px; height: 13px;">&nbsp;'
        || vCustCode
        || '</td>
            </tr>
            <tr style="height: 13.75px;">
                <td style="width: 265px; height: 13.75px;"><strong>&nbsp;Account Title</strong></td>
                <td style="width: 765.234px; height: 13.75px;">&nbsp;'
        || vAcTitle
        || '</td>
            </tr>
            <tr style="height: 13px;">
                <td style="width: 265px; height: 13px;"><strong>&nbsp;Product Name</strong></td>
                <td style="width: 765.234px; height: 13px;">&nbsp;'
        || vProductName
        || '</td>
            </tr>
            <tr style="height: 13px;">
                <td style="width: 265px; height: 13px;"><strong>&nbsp;Account Type</strong></td>
                <td style="width: 765.234px; height: 13px;">&nbsp;'
        || vActypeName
        || '</td>
            </tr>
            <tr style="height: 13px;">
                <td style="width: 265px; height: 13px;"><strong>&nbsp;Account Subtype Name</strong></td>
                <td style="width: 765.234px; height: 13px;">&nbsp;'
        || vAcSubTypName
        || '</td>
            </tr>
        </tbody>
    </table>
    <table class="table_4" style="height: 49px; ">
        <tbody>
            <tr>
                <td style="width: 1042px;">
                    <h6 style="text-align: center;">Personal Details</h6>
                </td>
            </tr>
        </tbody>
    </table>
    <table class="table_5" style="height: 32px;">
        <tbody>
            <tr>
                <td style="width: 265px;"><strong>&nbsp;Account Holder Name&nbsp; &nbsp;&nbsp;</strong></td>
                <td style="width: 768.234px;">&nbsp;'
        || vAcTitle
        || '</td>
            </tr>
            <tr>
                <td style="width: 265px;"><strong>&nbsp;Father Name</strong></td>
                <td style="width: 768.234px;">&nbsp;'
        || vFatherName
        || '</td>
            </tr>
            <tr>
                <td style="width: 265px;"><strong>&nbsp;Mother Name&nbsp;</strong></td>
                <td style="width: 768.234px;">&nbsp;'
        || vMotherName
        || '</td>
            </tr>
            <tr>
                <td style="width: 265px;"><strong>&nbsp;Spouse Name (If any)</strong></td>
                <td style="width: 768.234px;">&nbsp;'
        || vSpouseName
        || '</td>
            </tr>
            <tr>
                <td style="width: 265px;"><strong>&nbsp;Introducer Account (If any)&nbsp;</strong></td>
                <td style="width: 768.234px;">&nbsp;'
        || NVL (vIntrAcNo, '---')
        || '</td>
            </tr>
            <tr>
                <td style="width: 265px;"><strong>&nbsp;Introducer Name (If any)&nbsp;</strong></td>
                <td style="width: 768.234px;">&nbsp;'
        || NVL (vIntroName, '---')
        || '</td>
            </tr>
            <tr>
                <td style="width: 265px;"><strong>&nbsp;NID/ SID Number</strong></td>
                <td style="width: 768.234px;">&nbsp;'
        || NVL (vNidNo, '---')
        || '</td>
            </tr>
            <tr>
                <td style="width: 265px;"><strong>&nbsp;TIN </strong></td>
                <td style="width: 768.234px;">&nbsp;'
        || vTinNo
        || '</td>
            </tr>
            <tr>
                <td style="width: 265px;"><strong>&nbsp;VIN </strong></td>
                <td style="width: 768.234px;">&nbsp;'
        || vVinNo
        || '</td>
            </tr>
            <tr>
                <td style="width: 265px;"><strong>&nbsp;Birth Certificate</strong></td>
                <td style="width: 768.234px;">&nbsp;'
        || NVL (vBrcNo, '---')
        || '</td>
            </tr>
        </tbody>
    </table>
    <table class="table_6" style="height: 49px; ">
        <tbody>
            <tr>
                <td style="width: 1041px;">
                    <h6 style="text-align: center;">Address Information</h6>
                </td>
            </tr>
        </tbody>
    </table>
    <table class="table_7" style="height: 32px;">
        <tbody>
            <tr style="height: 13px;">
                <td style="width: 265px; height: 13px;"><strong>&nbsp;Present Address&nbsp; &nbsp;</strong></td>
                <td style="width: 766.234px; height: 13px;">&nbsp;'
        || vPrsAdress
        || '</td>
            </tr>
            <tr style="height: 13px;">
                <td style="width: 265px; height: 13px;"><strong>&nbsp;Permanent Address</strong></td>
                <td style="width: 766.234px; height: 13px;">&nbsp;'
        || vPerAdress
        || '</td>
            </tr>
            <tr style="height: 13px;">
                <td style="width: 265px; height: 13px;"><strong>&nbsp;Mobile No</strong></td>
                <td style="width: 766.234px; height: 13px;">&nbsp;'
        || NVL (vMobileNo, '---')
        || '</td>
            </tr>
            <tr style="height: 13.875px;">
                <td style="width: 265px; height: 13.875px;"><strong>&nbsp;Email</strong></td>
                <td style="width: 766.234px; height: 13.875px;">&nbsp;'
        || NVL (vMail, '---')
        || '</td>
            </tr>
            <tr style="height: 13px;">
                <td style="width: 265px; height: 13px;">&nbsp;</td>
                <td style="width: 766.234px; height: 13px;">&nbsp;</td>
            </tr>
        </tbody>
    </table>
    <p>&nbsp;</p>
    <table class="table_8" style="height: 79px;">
        <tbody>
            <tr>
                <td style="width: 20px;    font-weight:bold;">&nbsp;#Sl</td>
                <td style="width: 190px;    font-weight:bold;">&nbsp;Nominee Name</td>
                <td style="width: 190px;    font-weight:bold;">&nbsp;DOB</td>
                <td style="width: 190px;    font-weight:bold;">&nbsp;Share</td>
                <td style="width: 254.75px; font-weight:bold;">&nbsp;NID/ Birth Certificate</td>
            </tr>'
        || vNominee
        || '
            
        </tbody>
    </table>
    <p>&nbsp;</p>
    
    <div class="Signature-div">
        <div style="width:70%; text-align:left;border-top-color:black;">
            <p> <b ><span>Initial Approval (Sign) &nbsp</span><br></b>
                <span>Branch User ID:<b>&nbsp'
        || IniUserID
        || '</b></span><br>
                <span>Name:&nbsp'
        || IniUserName
        || '</span>
            </p>
        </div>
        <div style="width:30%; text-align:left;border-top-color:black;">
            <p> <b ><span>Final Approval (Sign) &nbsp</span><br></b>
                <span>Branch User ID:&nbsp<b>'
        || FinUserID
        || '</b></span><br>
                <span>Name:&nbsp'
        || FinUserName
        || '</span>
            </p>
        </div>
        </div>
</div>
</div>
</body>';

    vHtmlReport := vHeader || vBody;

    RETURN vHtmlReport;
END;
/
