REPORT ZPROG_003_01.
data: cl_calc TYPE REF TO zcl_calc_01,
      op type c,
      resultado type i.
SELECTION-SCREEN BEGIN OF BLOCK v1 WITH FRAME TITLE TEXT-005.
  PARAMETERS: n1 type i,
              n2 type i.

SELECTION-SCREEN END OF BLOCK v1.

SELECTION-SCREEN BEGIN OF BLOCK a1 WITH FRAME TITLE TEXT-005.
  PARAMETERS: som  RADIOBUTTON GROUP op DEFAULT 'X',
              sub  RADIOBUTTON GROUP op,
              mult  RADIOBUTTON GROUP op,
              div   RADIOBUTTON GROUP op.

SELECTION-SCREEN END OF BLOCK a1.

IF som = 'X' .
  op = '+'.
ELSEIF sub = 'X'.
  op = '-'.
  ELSEIF mult = 'X'.
    op = '*'.
    else.
      op = '/'.
ENDIF.

CREATE OBJECT cl_calc.
    cl_calc->set_calcular(
     EXPORTING
      n1 = n1
      n2 = n2
      op = op ).
    cl_calc->get_resultado( IMPORTING result = resultado ).
    WRITE: 'RESULTADO =',resultado.