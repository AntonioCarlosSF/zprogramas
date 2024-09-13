*&---------------------------------------------------------------------*
*& Report  YCARREGA_TABELAS_ESOCIAL
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT ycarrega_tabelas_esocial.


SELECTION-SCREEN BEGIN OF BLOCK a1 WITH FRAME TITLE text-001.

PARAMETERS: p_tab  AS CHECKBOX DEFAULT 'X',
            p_desc AS CHECKBOX.

SELECTION-SCREEN END OF BLOCK a1.


IF p_tab IS NOT INITIAL AND p_desc IS INITIAL.

  SELECT DISTINCT dd03l~tabname FROM dd03l
         INNER JOIN tadir
           ON dd03l~tabname = tadir~obj_name
         INNER JOIN dd02l                              "#EC CI_BUFFJOIN
           ON dd03l~tabname = dd02l~tabname
         APPENDING TABLE @DATA(lt_relevant_tables)
         WHERE dd03l~tabname LIKE 'T7BREFD_%'
           AND dd03l~fieldname = 'EVENT_ID'
           AND dd02l~tabclass  = 'TRANSP'
           AND dd02l~contflag  = 'A'
           AND tadir~devclass  IN ('PC37', 'PB37').

  cl_salv_table=>factory(
   IMPORTING
     r_salv_table = DATA(alv_table)
     CHANGING
       t_table    = lt_relevant_tables
       ).

  alv_table->display( ).

ELSEIF p_tab IS INITIAL AND p_desc IS NOT INITIAL.

  SELECT DISTINCT dd03l~tabname FROM dd03l
       INNER JOIN tadir
         ON dd03l~tabname = tadir~obj_name
       INNER JOIN dd02l                                "#EC CI_BUFFJOIN
         ON dd03l~tabname = dd02l~tabname
       APPENDING TABLE lt_relevant_tables
       WHERE dd03l~tabname LIKE 'T7BREFD_%'
         AND dd03l~fieldname = 'EVENT_ID'
         AND dd02l~tabclass  = 'TRANSP'
         AND dd02l~contflag  = 'A'
         AND tadir~devclass  IN ('PC37', 'PB37').




  SELECT SINGLE dd02t~ddtext
    FROM dd02t AS a
    INNER JOIN @DATA(lt_relevant_tables) AS b
    ON a~tabname = b~tabname
    INTO @DATA(lt_relevant_desc)
    WHERE dd02t~ddlanguage = 'PT'.

ELSE.
  MESSAGE 'Selecione apenas uma opção' TYPE 'E'.
ENDIF.
