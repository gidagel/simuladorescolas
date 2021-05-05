 [ sick?                ;; if true, the turtle is infectious
    estatico?            ;; se true a tartaruga fica parada durante a simulacao
    remaining-immunity   ;; how many weeks of immunity the turtle has left
    sick-time            ;; how long, in weeks, the turtle has been infectious
    age                  ;; how many weeks old the turtle is
]

globals
  [ infectado            ;; number os people infected
    %infectadoTotal      ;; what % of the population is infectious
    %immune              ;; what % of the population is immune
    numero-mortos        ;; contador para pessoas que morreram por acao da doenca apenas
    %numero-mortos       ;; %das pessoas que morreram por acao da doenca apenas
    reinfection-period   ;; periodo em dias para reintroduzir uma pessoa doente (simula transito de pessoas)
    reproduce-period     ;; quantidade de dias entre tentativas de reprodução
    lifespan             ;; the lifespan of a turtle
    chance-reproduce     ;; the probability of a turtle generating an offspring each tick
    carrying-capacity    ;; the number of turtles that can be in the world at one time
    immunity-duration    ;; how many weeks immunity lasts
    periodo-de-transmissão ;; for how long the person can contaminate
    chance-de-recuperação ;;tirei a chance de recuperacao da intereface
    dias                  ;; conta os escolares a cada 7 rodadas
    interacao-escolar     ;; numero de interacaoes escolares pode dia
    porcentagem-de-confinados ;; converte em porcentagem de confinamento
    chance-de-transmissão ;; converte em chance de transmissao
    número-de-pessoas     ;; numero de pessoas na grade
]

;; The setup is divided into four procedures
to setup
  clear-all
  setup-constants
  setup-turtles
  update-global-variables
  update-display
  reset-ticks
end

;; We create a variable number of turtles of which 10 are infectious,
;; and distribute them randomly
to setup-turtles
  create-turtles número-de-pessoas
    [ setxy random-xcor random-ycor
      set age random lifespan
      set sick-time 0
      set remaining-immunity 0
      set size 1.0  ;; easier to see
      set estatico? true ;; toda tartaruga e criada estatica
      get-healthy ]
  ask n-of 1 turtles    ;; number that begin infected
    [ get-sick ]
  ask n-of (número-de-pessoas * (1 - porcentagem-de-confinados / 100)) turtles
    [get-free]
end

to get-free
  set estatico? false
end

to get-locked-up
  set estatico? true
end

to get-sick ;; turtle procedure
  set sick? true
  set remaining-immunity 0
  set infectado infectado + 1
end

to get-healthy ;; turtle procedure
  set sick? false
  set remaining-immunity 0
  set sick-time 0
end

to become-immune ;; turtle procedure
  set sick? false
  set sick-time 0
  set remaining-immunity immunity-duration
end

;; This sets up basic constants of the model.
to setup-constants
  set lifespan 75 * 3 * 365      ;; 50 times 52 days = 50 years = 2600 weeks old
  set carrying-capacity 1000
  set chance-reproduce 1
  set periodo-de-transmissão 10 * 3
  set immunity-duration 365 ;; fixa em 1 ano
  set numero-mortos 0
  set reinfection-period 10 * 3
  set reproduce-period 360 ;; quantidade de dias entre tentativas de reprodução
  set chance-de-recuperação 99.3
  set interacao-escolar 3
  set dias 0
  ;; numero de pessoas na grade
  set número-de-pessoas espaço_físico_da_escola
 ;; if densidade-pessoa-por-área = "P" [set número-de-pessoas 110]
  ;;if densidade-pessoa-por-área = "M" [set número-de-pessoas 210]
  ;;if densidade-pessoa-por-área = "G" [set número-de-pessoas 307]
  ;; chance de transmissao
  if protocolos_de_segurança_e_higiene = "maioria respeita" [set chance-de-transmissão 39]
  if protocolos_de_segurança_e_higiene = "metade respeita" [set chance-de-transmissão 41]
  if protocolos_de_segurança_e_higiene = "minoria respeita" [set chance-de-transmissão 43]
  ;;% de confinamento
  if regras-de-distanciamento-social = "maioria respeita" [set porcentagem-de-confinados 70]
  if regras-de-distanciamento-social = "metade respeita" [set porcentagem-de-confinados 50]
  if regras-de-distanciamento-social = "minoria respeita" [set porcentagem-de-confinados 30]
end


to go
  ask turtles [
    get-older
    cond-move
    if sick? [ recover-or-die ]
    ifelse sick? [ infect ] [ maybe-reproduce ]
  ]
  if ticks mod reinfection-period = 29 [
    ask one-of turtles  [get-sick] ;; um individuo fica doente
  ]
  ;; Para convertes dias escolares em dias
  if ticks mod interacao-escolar = 0 [
     set dias dias + 1
  ]
  ;; início confinamento variável
  let num-confinados count turtles with [ estatico? ]
  let para-confinar ((count turtles) * (porcentagem-de-confinados / 100))
  let delta (para-confinar - num-confinados)
  ifelse delta > 0
    [ask n-of delta turtles with [ not estatico? ] [get-locked-up]]
    [ let minus-delta delta * (-1)
      ask n-of minus-delta turtles with [ estatico? ] [get-free]]
  ;; fim confinamento variável
  update-global-variables
  update-display
  tick
end

to maybe-reproduce
  ;; Mude o valor de reproduce-period para determinar a
  ;; a cada quantos dias a pessoa pode se reproduzir
  if ticks mod reproduce-period = 0 [
   reproduce
  ]
end

to cond-new-host
  if ticks mod reinfection-period = 0
    [ hatch 1
      [ set age  20 * 360 ;; essa idade é meio arbitraria
        get-free
        lt 45 fd 1
        get-sick
      ]
    ]
end

to update-global-variables
  if count turtles > 0
     ;;[set %infectadoTotal (  infectado / count turtles) * 100
    [ set %infectadoTotal (  count turtles with [ sick? ] / count turtles) * 100
      set %immune (count turtles with [ immune? ] / count turtles) * 100
      set %numero-mortos (  numero-mortos / número-de-pessoas) * 100
  ]
end
;;et %infectadoTotal (  infectado / count turtles) * 100
to update-display
  ask turtles
     [set shape "person" ;;[ if shape != forma-pessoa-ou-bola [ set shape forma-pessoa-ou-bola ]
      set color ifelse-value sick? [ red ] [ ifelse-value immune? [ grey ] [ green ] ] ]
  if focar-em-uma-pessoa? and subject = nobody
    [ watch one-of turtles with [ not hidden? ]
      clear-drawing
      ask subject [ pen-down ]
     ;; inspect subject
  ]
  if not focar-em-uma-pessoa? and subject != nobody
    [ stop-inspecting subject
      ask subject
        [ pen-up
          ask my-links [ die ] ]
      clear-drawing
      reset-perspective ]
end


;;Turtle counting variables are advanced.
to get-older ;; turtle procedure
  ;; Turtles die of old age once their age exceeds the
  ;; lifespan (set at 50 years in this model).
  set age age + 1
  if age > lifespan [ die ]
  if immune? [ set remaining-immunity remaining-immunity - 1 ]
  if sick? [ set sick-time sick-time + 1 ]
end

;; So move se turtle nao eh estatico
to cond-move
  if not estatico? [move]
end

;; Turtles move about at random.
to move ;; turtle procedure
  rt random 100
  lt random 100
  fd 1
end

;; If a turtle is sick, it infects other turtles on the same patch.
;; Immune turtles don't get sick.
to infect ;; turtle procedure
  ask other turtles-here with [ not sick? and not immune? ]
    [ if random-float 100 < chance-de-transmissão
      [ get-sick ] ]
end

;; Once the turtle has been sick long enough, it
;; either recovers (and becomes immune) or it dies.
to recover-or-die ;; turtle procedure
  if sick-time > periodo-de-transmissão                       ;; If the turtle has survived past the virus' duration, then
    [ ifelse random-float 100 < chance-de-recuperação   ;; either recover or die
      [ become-immune ]
      [ set numero-mortos numero-mortos + 1
        die ]
    ]
end

;; If there are less turtles than the carrying-capacity
;; then turtles can reproduce.
to reproduce
  if count turtles < carrying-capacity and random-float 100 < chance-reproduce
    [ hatch 1
      [ set age  360
        lt 45 fd 1
        get-healthy ] ]
end

to-report immune?
  report remaining-immunity > 0
end

to startup
  setup-constants ;; so that carrying-capacity can be used as upper bound of number-people slider
end


; Copyright 1998 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
270
95
540
365
-1
-1
7.72
1
10
1
1
1
0
1
1
1
-17
17
-17
17
1
1
1
ticks
30

BUTTON
270
50
390
83
Resetar
Setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
400
50
510
83
Iniciar/Parar
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
560
100
909
365
População
interações
pessoas
0
10
0
40
true
true
"" ""
PENS
"infectado" 1 0 -2674135 true "" "plot count turtles with [ sick? ]"
"imune" 1 0 -7500403 true "" "plot count turtles with [ immune? ]"

MONITOR
630
50
731
95
% infectados/dia
%infectadoTotal
1
1
11

MONITOR
735
50
816
95
% imunes /dia
%immune
1
1
11

MONITOR
560
50
626
95
dias letivos
dias
1
1
11

MONITOR
820
50
915
95
% mortos (virus)
%numero-mortos
1
1
11

TEXTBOX
5
315
230
356
Copyright 2020 José Paulo Guedes Pinto, Patrícia Camargo Magalhães, Carlos da Silva dos Santos [CC BY-NC-SA 3.0]
10
0
1

TEXTBOX
0
12
240
55
1º PASSO: defina e insira as características da sua escola para realizar a simulação!
12
0
1

TEXTBOX
270
10
530
51
2º PASSO: primeiro aperte o botão Resetar e depois Iniciar/Parar para rodar a simulação.
12
0
1

TEXTBOX
560
10
880
45
3º PASSO: Acompanhe a simulação nos painéis de contaminação e a evolução da curva no gráfico abaixo. 
12
0
1

SWITCH
0
260
240
293
focar-em-uma-pessoa?
focar-em-uma-pessoa?
0
1
-1000

CHOOSER
0
195
240
240
regras-de-distanciamento-social
regras-de-distanciamento-social
"maioria respeita" "metade respeita" "minoria respeita"
2

CHOOSER
0
135
240
180
protocolos_de_segurança_e_higiene
protocolos_de_segurança_e_higiene
"maioria respeita" "metade respeita" "minoria respeita"
0

SLIDER
0
55
240
88
espaço_físico_da_escola
espaço_físico_da_escola
35
400
210
1
1
NIL
HORIZONTAL

TEXTBOX
45
95
200
113
disperso<------>comprimido
12
0
1
@#$#@#$#@
## O QUE É ISSO?

A construção desse modelo foi inspirada pelo sucesso da divulgação do estudo desenvolvido por Harry Stevens e publicado na página do jornal Washington Post dia 14 de Março de 2020 (https://www.washingtonpost.com/graphics/2020/world/corona-simulator/) onde o autor explora diferentes cenarios de atenuação e supressão social para conter o avanço do coronavírus. 

Para a construção do Modelo de Dispersão do Coronavírus (MD Corona), modificamos o modelo original Vírus (Wilensky, 1998) presente na biblioteca do software livre NetLogo (Wilensky, 1999). O modelo original foi inspirado pelo artigo de Yorke et al (1979) em que biólogos ecologistas sugeriram um número de fatores que poderiam influenciar a sobrevivência de um vírus com transmissão direta entre uma população. As modificações específicas que fazem parte do MD Corona serão destacadas abaixo.

## COMO ELE FUNCIONA
Antes de iniciar as simulações o usuário pode modificar a densidade do espaço físico da escola (disperso - comprimido), a adoção das regras de distanciamento social e dos protocolos de segurança e higiene. Durante as simulações o usuário pode reiniciá-las o detê-las para modificar os parâmetros mencionados anteriormente.
As pessoas são distribuídas e interagem aleatoriamente nesse mundo (o quadrado preto) estando em um dos três estados:
a) saudável mas suscetível a ser contaminado pelo vírus (verde) 
b) infectadas e transmitindo o vírus (vermelho)
c) saudáveis e imunes (cinza)

### A densidade populacional
A densidade Populacional afeta o quão frequente pessoas infectadas, imunes e susceptíveis podem entrar em contato umas com as outras. A densidade populacional pode ser modificada através do slider  espaço_físico_da_escola.

### Probabilidade de transmissão
Com que facilidade o vírus se espalha? Alguns vírus com os quais estamos familiarizados se espalham com muita facilidade. Alguns vírus se espalham com pouco contato todas as vezes. Outros (o vírus HIV por exemplo, que é responsável pela Aids) requerem contato significativo, muitas vezes repetidas, antes da transmissão do vírus. Neste modelo, O slider protocolos_de_seguranção_e_higiene permite configurar a probabilidade de transmissão do vírus em 43%, 41% e 39% dependendo se a maioria, metade e minoria da população respeitam os protocolos de segurança e higiene.
### Distanciamento social
As regras de distanciamento social limitam as interações entre as pessoas ao suprimir sua movimentação a 70%, 50% e 30 % dependendo se  a maioria, metade e minoria da população respeitam essas regras. O slider regras_de_distanciamento_social modificam este parametro.

### Periodo de  transmissão
Quanto tempo uma pessoa fica infectada antes de se recuperar ou morrer? Esse período de tempo é essencialmente a janela de oportunidade do vírus para transmissão para novos hospedeiros. Neste modelo, a duração da janela de transmissão é fixa em 10 dias, o equivalente a 14 dias sem contar o final de semana, em que as escolas não abrem. Este valor foi considerado já que a OMS estabeleceu que as pessoas infectadas deveriam permanecer isoladas durante 14 dias.

### Grau de imunidade
Se uma pessoa for infectada  e se recuperar, o quão imune ela estará do vírus? 
Para algumas doenças a imunidade dura a vida inteira e é garantida, mas, em alguns casos, a imunidade desaparece com o tempo e ele pode não ser absolutamente segura. No caso do coronavirus não sabemos exatamente qual é o tempo de duração da imunidade. Após 6 meses de pandemia ainda não é comum casos de reinfecção confirmados (primeiro caso reportado no Brasil a pouco). Neste caso mantivemos como no modelo original do Netlogo,  o período de imunidade como sendo um ano.

### Interações durante o período escolar 
Considerou-se três interações durante o período letivo (um dia), pois durante a entrada, o recesso e a saída dos estudantes acontecem a maioria das interações entre eles.  
### Rotatividade da população
Todos os novos indivíduos que nascerem, substituindo os que morrerem, serão saudáveis e suscetíveis. Nesse modelo as pessoas morrem por infecção ou de velhice. 

### Parâmetros constantes
Quatro parâmetros importantes deste modelo são definidos como constantes no código (consulte o procedimento `inicializar-constantes`). Eles podem ser expostos como sliders, se desejado. O tempo de vida das pessoas (75 anos expectativa de vida no Brasil em 2020), a capacidade máxima de pessoas na grade é de 400, a chance de recuperação uma vez contraído o vírus é 99.3%, o número inicial de pessoas infectadas é 1. 
No  modelo um agente infectado pelo vírus  é reintroduzido a cada 30 rodadas (10 dias letivos), isto torna o ambiente do modelo aberto (antes era fechado) e aproxima o modelo à realidade de surgimento de novos surtos. 

## COMO USAR O MD CORONA
O slider espaço_físico_das_pessoas define a densidade das escolas, onde as pessoas (35 a 400) serão aleatóriamente distribuidas no ambiente.
O slider regras_de_distanciamento_social determina o número de pessoas que estarão aleatoriamente paradas no ambiente. 
O slider protocolos_de_segurança_e_higiene determina a probabilidade de transmissão do vírus quando uma pessoa infectada e outra suscetível ocupar o mesmo sítio no ambiente. 
O botão Resetar recomeça os gráficos e distribui aleatoriamente o número de pessoas no ambiente. Todas as pessoas, exceto 1, são consideradas saudáveis e suscetíveis ao vírus (pessoas verdes).  O programa fixa 1 pessoa inicialmente infectada (pessoa vermelha). Todos com idades distribuídas aleatoriamente. O botão Iniciar/Parar inicia a simulação e os gráficos e também para a simulação.
O botão Focar_em_uma_pessoa permite focalizar no deslocamento e as interações de somente uma pessoa.
Quatro monitores de saída mostram o número de dias electivos, porcentagem de infectados por dia, porcentagem de imunes por dia e porcentagem total de infectados. O gráfico mostra o número de pessoas infectadas (vermelho) e imunes (cinza). O eixo x do gráfico corresponde às interações realizadas por dia e o eixo y representa o número de pessoas (infectadas ou imunes dependendo da curva vermelha ou azul respectivamente).


## MODELOS RELACIONADOS

* HIV
* Virus em uma rede

## CREDITOS E REFERÊNCIAS 

Este modelo pode mostrar uma visualização alternativa usando círculos para representar as pessoas. Ele usa técnicas de visualização conforme recomendado no artigo:
Kornhauser, D., Wilensky, U., & Rand, W. (2009). Design guidelines for agent based model visualization. Journal of Artificial Societies and Social Simulation, JASSS, 12(2), 1.

## COMO CITAR

Se você mencionar este modelo ou o software NetLogo numa publicação, pedimos para que inclua as citações abaixo.

Para o modelo Virus:

* Wilensky, U. (1998).  NetLogo Virus model.  http://ccl.northwestern.edu/netlogo/models/Virus.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Para o modelo MD Corona:

* Guedes Pinto, José Paulo; Magalhães, Patrícia; Santos Carlos Silva. (2020). Modelo de Dispersão Comunitária Coronavírus (MD Corona), Universidade Federal do ABC, São Bernardo do Campo, Brasil. 

Por favor cite o software NetLogo como:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2020 José Paulo Guedes Pinto, Patrícia Camargo Magalhães, Carlos da Silva dos Santos

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

Copyright 1998 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

Esse trabalho está sob a licença Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  Para ver uma cópia dessa licença visite: https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Liceças comercial também estão dispponíveis. Para indigar sobre isso, favor contactar Uri Wilensky at uri@northwestern.edu.

O modelo MD Corona foi criado para gerar dados para o working paper "Simulando a evolução da transmissão comunitária do coronavírus através do Modelo M D Corona." de autoria do José Paulo Guedes Pinto, Patrícia Magalhães e Carlos da Silva Santos. 2020.


This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.

<!-- 1998 2001 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0
-0.2 0 0 1
0 1 1 0
0.2 0 0 1
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@

@#$#@#$#@
