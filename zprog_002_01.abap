REPORT zprog_002_01.
DATA: lv_m   TYPE c LENGTH 50,
      lv_ind TYPE i.
lv_ind = 1.
lv_m = 'ABAP É O MÁXIMO'.

WHILE lv_ind <= 20.
  IF lv_ind = 18.
    WRITE: / 'linha 18' CENTERED.
    lv_ind = lv_ind + 1.
    CONTINUE.
  ENDIF.
  IF lv_ind MOD 2 = 0.
    WRITE:/ lv_m LEFT-JUSTIFIED.
  ELSE.
    WRITE: / lv_m RIGHT-JUSTIFIED.


  ENDIF.
  lv_ind = lv_ind + 1.
ENDWHILE.