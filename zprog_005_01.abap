REPORT ZPROG_005_01.
data: op type c LENGTH 1,
      result type i.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

PARAMETERS: n1 type i,
            n2 type i.


SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK a1 WITH FRAME TITLE TEXT-001.

PARAMETERS: som RADIOBUTTON GROUP calc ,
            sub RADIOBUTTON GROUP calc,
            mult RADIOBUTTON GROUP calc,
            div RADIOBUTTON GROUP calc.

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


CALL FUNCTION 'ZCALCULADORA_01'
  EXPORTING
    num1 = n1
    num2 = n2
    operacao = op
  IMPORTING
    resultado = result
EXCEPTIONS
  div_zero = 1
  OTHERS = 2.

  IF sy-subrc = 1.
    WRITE: / 'Erro, não existe divisão por zero'.
    ELSEIF sy-subrc = 2.
      write / 'ERRO DESCONHECIDO'.
    ELSE.
  WRITE: / 'Resultado =', result.
  ENDIF.