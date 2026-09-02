       01  EPMENUI.
           02  FILLER PIC X(12).
           02  LITLOANL    COMP  PIC  S9(4).
           02  LITLOANF    PICTURE X.
           02  FILLER REDEFINES LITLOANF.
             03 LITLOANA    PICTURE X.
           02  FILLER   PICTURE X(2).
           02  LITLOANI  PIC X(23).
           02  EPLOANL    COMP  PIC  S9(4).
           02  EPLOANF    PICTURE X.
           02  FILLER REDEFINES EPLOANF.
             03 EPLOANA    PICTURE X.
           02  FILLER   PICTURE X(2).
           02  EPLOANI  PIC X(12).
           02  LITYEARSL    COMP  PIC  S9(4).
           02  LITYEARSF    PICTURE X.
           02  FILLER REDEFINES LITYEARSF.
             03 LITYEARSA    PICTURE X.
           02  FILLER   PICTURE X(2).
           02  LITYEARSI  PIC X(24).
           02  EPYEARSL    COMP  PIC  S9(4).
           02  EPYEARSF    PICTURE X.
           02  FILLER REDEFINES EPYEARSF.
             03 EPYEARSA    PICTURE X.
           02  FILLER   PICTURE X(2).
           02  EPYEARSI  PIC X(2).
           02  EPDIFF1L    COMP  PIC  S9(4).
           02  EPDIFF1F    PICTURE X.
           02  FILLER REDEFINES EPDIFF1F.
             03 EPDIFF1A    PICTURE X.
           02  FILLER   PICTURE X(2).
           02  EPDIFF1I  PIC X(22).
           02  EPRATEL    COMP  PIC  S9(4).
           02  EPRATEF    PICTURE X.
           02  FILLER REDEFINES EPRATEF.
             03 EPRATEA    PICTURE X.
           02  FILLER   PICTURE X(2).
           02  EPRATEI  PIC X(5).
           02  EPDIFF2L    COMP  PIC  S9(4).
           02  EPDIFF2F    PICTURE X.
           02  FILLER REDEFINES EPDIFF2F.
             03 EPDIFF2A    PICTURE X.
           02  FILLER   PICTURE X(2).
           02  EPDIFF2I  PIC X(22).
           02  EPPAYMNTL    COMP  PIC  S9(4).
           02  EPPAYMNTF    PICTURE X.
           02  FILLER REDEFINES EPPAYMNTF.
             03 EPPAYMNTA    PICTURE X.
           02  FILLER   PICTURE X(2).
           02  EPPAYMNTI  PIC X(12).
           02  MSGERRL    COMP  PIC  S9(4).
           02  MSGERRF    PICTURE X.
           02  FILLER REDEFINES MSGERRF.
             03 MSGERRA    PICTURE X.
           02  FILLER   PICTURE X(2).
           02  MSGERRI  PIC X(40).
       01  EPMENUO REDEFINES EPMENUI.
           02  FILLER PIC X(12).
           02  FILLER PICTURE X(3).
           02  LITLOANC    PICTURE X.
           02  LITLOANH    PICTURE X.
           02  LITLOANO  PIC X(23).
           02  FILLER PICTURE X(3).
           02  EPLOANC    PICTURE X.
           02  EPLOANH    PICTURE X.
           02  EPLOANO  PIC X(12).
           02  FILLER PICTURE X(3).
           02  LITYEARSC    PICTURE X.
           02  LITYEARSH    PICTURE X.
           02  LITYEARSO  PIC X(24).
           02  FILLER PICTURE X(3).
           02  EPYEARSC    PICTURE X.
           02  EPYEARSH    PICTURE X.
           02  EPYEARSO  PIC X(2).
           02  FILLER PICTURE X(3).
           02  EPDIFF1C    PICTURE X.
           02  EPDIFF1H    PICTURE X.
           02  EPDIFF1O  PIC X(22).
           02  FILLER PICTURE X(3).
           02  EPRATEC    PICTURE X.
           02  EPRATEH    PICTURE X.
           02  EPRATEO  PIC X(5).
           02  FILLER PICTURE X(3).
           02  EPDIFF2C    PICTURE X.
           02  EPDIFF2H    PICTURE X.
           02  EPDIFF2O  PIC X(22).
           02  FILLER PICTURE X(3).
           02  EPPAYMNTC    PICTURE X.
           02  EPPAYMNTH    PICTURE X.
           02  EPPAYMNTO  PIC X(12).
           02  FILLER PICTURE X(3).
           02  MSGERRC    PICTURE X.
           02  MSGERRH    PICTURE X.
           02  MSGERRO  PIC X(40).