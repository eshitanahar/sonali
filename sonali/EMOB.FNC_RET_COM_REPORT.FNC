CREATE OR REPLACE FUNCTION EMOB.FNC_RET_COM_REPORT (pMonthCode     VARCHAR2,
                                                    pBranchCode    VARCHAR2,
                                                    pPostDate      DATE,
                                                    pAppUser       VARCHAR2)
   RETURN CLOB
IS
   vTotalDebit     NUMBER := 0;
   vTotalCredit    NUMBER := 0;
   vBranchName     VARCHAR2 (200);
   vRetRepFormat   CLOB;
   vMonth          VARCHAR2 (200) := pMonthCode;
   vPostDate       VARCHAR2 (100);

   CURSOR DEBIT_LIST
   IS
        SELECT Y.GLAC_NAME || ' - ' || Y.CBS_GL DR_AC_NO,
               SUM (DEBIT_AMT) DEBIT_AMT
          FROM (  SELECT SUM (AGENT_CHARGE) DEBIT_AMT, PAYABLE_GLID
                    FROM EMOB.MB_TRAN_COMM_PROVISION A, EMOB.ST_AGENT_POINT B
                   WHERE     POST_FLAG = 'Y'
                         AND A.POINT_ID = B.POINT_ID
                         AND A.MONTH_CODE = pMonthCode
                         AND B.BRANCH_CODE = pBranchCode
                GROUP BY A.PAYABLE_GLID /*UNION ALL
                                          SELECT SUM (VAT_AMOUNT) DEBIT_AMT, PAYABLE_GLID
                                            FROM EMOB.MB_TRAN_COMM_PROVISION A, EMOB.ST_AGENT_POINT B
                                           WHERE     POST_FLAG = 'Y'
                                                 AND A.POINT_ID = B.POINT_ID
                                                 AND A.MONTH_CODE = pMonthCode
                                                 AND B.BRANCH_CODE = pBranchCode
                                        GROUP BY A.PAYABLE_GLID*/
                UNION ALL
                  SELECT SUM (MOTHER_AGENT_CHARGE) DEBIT_AMT, PAYABLE_GLID
                    FROM EMOB.MB_TRAN_COMM_PROVISION A, EMOB.ST_AGENT_POINT B
                   WHERE     NVL (MOTHER_AGENT_POST_FLAG, 'N') = 'Y'
                         AND A.MOTHER_AGENT_CUST_NO = B.AGENT_ID
                         AND A.MONTH_CODE = pMonthCode
                         AND B.BRANCH_CODE = pBranchCode
                         AND NVL (MOTHER_AGENT_CHARGE, 0) > 0
                GROUP BY PAYABLE_GLID) X,
               EMOB.MB_GLAC_MST Y
         WHERE X.PAYABLE_GLID = Y.GLAC_ID
      GROUP BY PAYABLE_GLID, Y.GLAC_NAME || ' - ' || Y.CBS_GL;

   -------CREDIT lIST
   CURSOR CREDIT_LIST
   IS
        SELECT SUM (CR_AMOUNT) CR_AMOUNT, CR_AC_NO
          FROM (  SELECT (  SUM (AGENT_CHARGE)
                          - ROUND (
                                 SUM (
                                    DECODE (VAT_APPLICABLE, 'N', 0, AGENT_CHARGE))
                               * 15
                               / 115,
                               2))
                            CR_AMOUNT,
                         (SELECT AC_TITLE || ' - ' || AC_NO
                            FROM EMOB.MB_ACCOUNT_MST
                           WHERE AC_ID = A.AGENT_AC_ID)
                            CR_AC_NO
                    FROM EMOB.MB_TRAN_COMM_PROVISION A, EMOB.ST_AGENT_POINT B
                   WHERE     POST_FLAG = 'Y'
                         AND A.POINT_ID = B.POINT_ID
                         AND A.MONTH_CODE = pMonthCode
                         AND B.BRANCH_CODE = pBranchCode
                GROUP BY A.AGENT_AC_ID
                UNION ALL
                  SELECT (  SUM (MOTHER_AGENT_CHARGE)
                          - ROUND (SUM (MOTHER_AGENT_CHARGE) * 15 / 115, 2))
                            CR_AMOUNT,
                         (SELECT AC_TITLE || ' - ' || AC_NO
                            FROM EMOB.MB_ACCOUNT_MST
                           WHERE AC_ID = A.MOTHER_AGENT_AC_ID)
                            CR_AC_NO
                    FROM EMOB.MB_TRAN_COMM_PROVISION A, EMOB.ST_AGENT_POINT B
                   WHERE     NVL (MOTHER_AGENT_POST_FLAG, 'N') = 'Y'
                         AND A.MOTHER_AGENT_CUST_NO = B.AGENT_ID
                         AND A.MONTH_CODE = pMonthCode
                         AND B.BRANCH_CODE = pBranchCode
                         AND NVL (MOTHER_AGENT_CHARGE, 0) > 0
                GROUP BY MOTHER_AGENT_AC_ID
                UNION ALL
                  SELECT ROUND (
                              SUM (DECODE (VAT_APPLICABLE, 'N', 0, AGENT_CHARGE))
                            * 15
                            / 115,
                            2)
                            CR_AMOUNT,
                         (SELECT GLAC_NAME || ' - ' || CBS_GL
                            FROM EMOB.MB_GLAC_MST
                           WHERE GLAC_ID = A.VAT_GLID)
                            CR_AC_NO
                    FROM EMOB.MB_TRAN_COMM_PROVISION A, EMOB.ST_AGENT_POINT B
                   WHERE     POST_FLAG = 'Y'
                         AND A.POINT_ID = B.POINT_ID
                         AND A.MONTH_CODE = pMonthCode
                         AND B.BRANCH_CODE = pBranchCode
                GROUP BY A.VAT_GLID
                UNION ALL
                  SELECT ROUND (SUM (MOTHER_AGENT_CHARGE) * 15 / 115, 2)
                            CR_AMOUNT,
                         (SELECT GLAC_NAME || ' - ' || CBS_GL
                            FROM EMOB.MB_GLAC_MST
                           WHERE GLAC_ID = A.VAT_GLID)
                            CR_AC_NO
                    FROM EMOB.MB_TRAN_COMM_PROVISION A, EMOB.ST_AGENT_POINT B
                   WHERE     NVL (MOTHER_AGENT_POST_FLAG, 'N') = 'Y'
                         AND A.MOTHER_AGENT_CUST_NO = B.AGENT_ID
                         AND A.MONTH_CODE = pMonthCode
                         AND B.BRANCH_CODE = pBranchCode
                         AND NVL (MOTHER_AGENT_CHARGE, 0) > 0
                GROUP BY A.VAT_GLID) X
      GROUP BY CR_AC_NO;
BEGIN
   SELECT BRANCH_CODE || ' - ' || BRANCH_NAME
     INTO vBranchName
     FROM EMOB.CBS_BRANCH_LIST
    WHERE BRANCH_CODE = pBranchCode;

   SELECT MAX (POST_DATE)
     INTO vPostDate
     FROM EMOB.MB_TRAN_COMM_PROVISION A, EMOB.ST_AGENT_POINT B
    WHERE     POST_FLAG = 'Y'
          AND A.POINT_ID = B.POINT_ID
          AND A.MONTH_CODE = pMonthCode
          AND B.BRANCH_CODE = pBranchCode;

   vRetRepFormat :=
         '<!DOCTYPE html>
<html>
<body>
<div id="printableArea">
<p>
<h3>SONALI BANK LIMITED</h3>
<h5>Branch: '
      || vBranchName
      || '
<h6>Agent Banking Commission Posting Voucher</h6>
<h6>Month: '
      || TO_CHAR (TO_DATE (vMonth, 'YYYYMM'), 'YYYY MONTH')
      || '</h6> <h6>Posting Date: '
      || vPostDate
      || '</h6>
</P>
<table>
  <tr>
    <th style="width:200px;">Debit Account No.</th>
    <th style="width:80px; text-align:end;">Debit Amount</th>
  </tr>';


   FOR I IN DEBIT_LIST
   LOOP
      vRetRepFormat :=
            vRetRepFormat
         || '
  <tr>
    <td>'
         || I.DR_AC_NO
         || '</td>
    <td style=" text-align:right;" ">'
         || TO_CHAR (I.DEBIT_AMT, '999999999999D00')
         || '</td>
  </tr>

'      ;
      vTotalDebit := vTotalDebit + I.DEBIT_AMT;
   END LOOP;

   vRetRepFormat :=
         vRetRepFormat
      || '<tr>
    <td style="width:200px; font-weight:700; text-align:right;">Total Debit :</td>
    <td style="width:80px; font-weight:700; text-align:right;">'
      || TO_CHAR (vTotalDebit, '999999999999D00')
      || '</td>
  </tr>
</table>
<br>
<table>
  <tr>
    <th style="width:200px;">Credit Account No.</th>
    <th style="width:80px; text-align:end;">Credit Amount</th>
  </tr>';


   FOR J IN CREDIT_LIST
   LOOP
      vRetRepFormat :=
            vRetRepFormat
         || '
  <tr>
    <td>'
         || J.CR_AC_NO
         || '</td>
    <td style=" text-align:right;" ">'
         || TO_CHAR (J.CR_AMOUNT, '999999999999D00')
         || '</td>
  </tr>

'      ;
      vTotalCredit := vTotalCredit + J.CR_AMOUNT;
   END LOOP;

   vRetRepFormat :=
         vRetRepFormat
      || '<tr>
    <td style="width:200px; font-weight:700; text-align:right;">Total Credit :</td>
    <td style="width:80px; font-weight:700; text-align:right;">'
      || TO_CHAR (vTotalCredit, '999999999999D00')
      || '</td>
  </tr>
</table>
</body>
<footer>
<table style="width:100%; border:none;">
<tr>
<th style="width:100px;border:none;"><b> USER : '
      || pAppUser
      || ' </b></th><th style="width:100px;border:none;text-align:right;"><i>Printing Date and Time: '
      || TO_CHAR (SYSTIMESTAMP, 'MONTH DD, YYYY DAY HH12:MI:SS AM')
      || '</i>  </th>
</tr>

</table>
</footer>
</div>
</html>';
   RETURN vRetRepFormat;
END;
/
