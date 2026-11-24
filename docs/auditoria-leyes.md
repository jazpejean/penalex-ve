# Auditoría de puntuación del corpus legal

Tras corregir los datos en R2: **cero** signos iniciales, **cero** dobles espacios y **cero** espacios antes de puntuación.

Quedan **65 casos** que requieren criterio jurídico, con el texto completo y el error marcado entre ⟦⟧.

| Tipo | Casos |
|---|---|
| Punto seguido de mayúscula sin espacio | 36 |
| Minúscula después de punto | 29 |

## Punto seguido de mayúscula sin espacio

### codigo-organico-de-justicia-militar · art. 143

**Error detectado:** …e extenderá a continuación de la sentencia, firmado por todo ⟦s.N⟧ o se considerará como sentencia ni se ejecutará la decisión …

**Texto completo:**

> La Sentencia se dictará por mayoría de votos, expresará la fecha en que se haya dictado y se firmará por los miembros del Tribunal, pero los que hayan disentido respecto de lo dispuesto, podrán salvar su voto, el cual se extenderá a continuación de la sentencia, firmado por todos.No se considerará como sentencia ni se ejecutará la decisión a cuyo pronunciamiento no hayan concurrido todos los Jueces llamados por la ley, ni la que no este firmada por todos ellos.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-organico-de-justicia-militar · art. 470

**Error detectado:** …momento de la comisión del delito al servicio de la Repúblic ⟦a.T⟧ ambién incurren en este delito los extranjeros que tengan má…

**Texto completo:**

> Es requisito necesario para incurrir en el delito de traición a la patria, que el delincuente sea venezolano o que se encuentre en el momento de la comisión del delito al servicio de la República.También incurren en este delito los extranjeros que tengan más de diez años radicados en Venezuela, a menos, y sólo en caso de guerra, que esta sea en contra de su país.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-organico-de-justicia-militar · art. 520

**Error detectado:** …nte al enemigo, será castigado con prisión de dos a seis año ⟦s.C⟧ uando la desobediencia no hubiese ocasionado daño o perturba…

**Texto completo:**

> Si la desobediencia hubiese causado daño o perturbación en el servicio, se castigará con prisión de uno a dos años; y si este delito se cometiese frente al enemigo, será castigado con prisión de dos a seis años.Cuando la desobediencia no hubiese ocasionado daño o perturbación en el servicio, será castigado con tres a seis meses de arresto.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-penal · art. 20

**Error detectado:** …rá ser más de una vez cada día ni menos de una vez por seman ⟦a.E⟧ s pena accesoria a la de confinamiento la suspensión, mientr…

**Texto completo:**

> La pena de confinamiento consiste en la obligación impuesta al reo, de residir, durante el tiempo de la condena, en el Municipio que indique la sentencia firme que la aplique, no pudiendo designarse al efecto ninguno que diste menos de cien kilómetros, tanto de aquel donde se cometió el delito como de aquéllos en que estuvieron domiciliados, el reo al tiempo de la comisión del delito, y el ofendido para la fecha de la sentencia de Primera Instancia.
> 
> El penado estará obligado, en comprobación de estar cumpliendo la sentencia y mientras dure la condena, a presentarse a la Jefatura Civil del Municipio con la frecuencia que el Jefe Civil indique, la cual no podrá ser más de una vez cada día ni menos de una vez por semana.Es pena accesoria a la de confinamiento la suspensión, mientras se la cumple, del empleo que ejerza el reo.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-penal · art. 217

**Error detectado:** …ometiere con armas, la prisión será de tres meses a tres año ⟦s.S⟧ i al primer requerimiento de la autoridad se disolviere la a…

**Texto completo:**

> El que haga parte de una asociación de diez o más personas que tengan por objeto cometer, por medio de violencia o amenaza, el hecho previsto en el artículo precedente, será castigado con prisión de un mes a dos años.
> 
> Si el hecho se cometiere con armas, la prisión será de tres meses a tres años.Si al primer requerimiento de la autoridad se disolviere la asociación, las personas que hubieren hecho parte de ella no incurrirán en ninguna responsabilidad criminal por el hecho previsto en este artículo.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-penal · art. 270

**Error detectado:** …con armas, será castigado con el duplo de la pena establecid ⟦a.Y⟧  si resultare cometida lesión corporal o algún otro delito, …

**Texto completo:**

> El que, con el objeto sólo de ejercer un pretendido derecho, se haga justicia por sí mismo, haciendo uso de la violencia sobre las cosas, cuando podía haber ocurrido a la autoridad, será castigado con multa de doscientas cincuenta unidades tributarias (250 U.T.) a dos mil unidades tributarias (2.000 U.T.).
> 
> Si el culpable se valiere de amenaza o violencia contra las personas, aunque no haya empleado violencia sobre las cosas será castigado con prisión de uno a seis meses o confinamiento de tres meses a un año.
> 
> Si la violencia se ha cometido con armas, será castigado con el duplo de la pena establecida.Y si resultare cometida lesión corporal o algún otro delito, será castigado con la pena correspondiente a estos hechos punibles.
> 
> Si el hecho no fuere acompañado de otro delito enjuiciable de oficio, no se procederá sino a instancia de parte.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-penal · art. 330

**Error detectado:** …n aplicables al que haya dado el dinero o los otros presente ⟦s.T⟧ odo lo dado será confiscado.

**Texto completo:**

> Todo médico, cirujano o empleado de sanidad, que por favor haya dado una falsa certificación destinada a hacer fe ante la autoridad, será castigado con arresto hasta por quince días o multa de cincuenta unidades tributarias (50 U.T.) a doscientas cincuenta unidades tributarias (250 U.T.). Al que hubiere hecho uso de la falsa certificación, se le aplicará la misma pena.
> 
> Si por causa de la falsa certificación se ha admitido o mantenido en un asilo de enajenados a alguna persona en su cabal juicio, o si resulta algún otro mal importante, la pena será de arresto de tres a dieciocho meses.
> 
> Si el hecho se hubiese cometido mediante dinero u otras dádivas, entregadas o prometidas, para sí o para un tercero, el arresto será por tiempo de cuarenta y cinco días a doce meses. Y lo será por tiempo de uno a tres años, si la certificación ha tenido las consecuencias previstas en el aparte precedente.
> 
> Las penas indicadas en los dos apartes precedentes serán también aplicables al que haya dado el dinero o los otros presentes.Todo lo dado será confiscado.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-penal · art. 546

**Error detectado:** …en la Gaceta Oficial de la República Bolivariana de Venezuel ⟦a.D⟧ ado, firmado y sellado en el Palacio Federal Legislativo, se…

**Texto completo:**

> Se deroga el Código Penal de 30 de junio de 1915.El presente Código reformado empezará a regir desde su publicación en la Gaceta Oficial de la República Bolivariana de Venezuela.Dado, firmado y sellado en el Palacio Federal Legislativo, sede de la Asamblea Nacional, en Caracas, a los tres días del mes de marzo de dos mil cinco. Año 194 de la Independencia y 145 de la Federación.

`[ ] Es correcto`  `[ ] Es un error`

### copp · art. 51

**Error detectado:** …unciones, caso en el cual corresponderá al Ministerio Públic ⟦o.C⟧ uando los delitos hayan afectado intereses colectivos o difu…

**Texto completo:**

> Cuando se trate de delitos que han afectado el patrimonio de la República, de los Estados o de los Municipios la acción civil será ejercida por el Procurador o Procuradora General de la República, o por los Procuradores o Procuradoras de los Estados o por los o las Síndicos Municipales, respectivamente, salvo cuando el delito haya sido cometido por un funcionario o público o funcionaria pública en el ejercicio de sus funciones, caso en el cual corresponderá al Ministerio Público.Cuando los delitos hayan afectado intereses colectivos o difusos la acción civil será ejercida por el Ministerio Público.
> 
> Cuando en la comisión del delito haya habido concurrencia de un particular con el funcionario público o funcionaria pública, el ejercicio de la acción civil corresponderá al Ministerio Público.
> 
> El Procurador o Procuradora General de la República o el o la Fiscal General de la República, según el caso, podrán decidir que la acción sea planteada y proseguida por otros órganos del Estado o por entidades civiles.

`[ ] Es correcto`  `[ ] Es un error`

### copp · art. 295

**Error detectado:** …idualización del imputado o imputada o del acto de imputació ⟦n.V⟧ encido este lapso, el imputado o la víctima podrán requerir …

**Texto completo:**

> El Ministerio Público procurará dar término a la fase preparatoria con la diligencia que el caso requiera en un lapso de seis meses contado a partir de la individualización del imputado o imputada o del acto de imputación.Vencido este lapso, el imputado o la víctima podrán requerir al Juez o Jueza de Control la fijación de un plazo prudencial, de treinta días para la conclusión de la investigación.
> 
> En las causas que se refieran a la investigación de delitos de homicidio intencional, violación; delitos que atenten contra la libertad, integridad e indemnidad sexual de niños, niñas y adolescentes; secuestro, corrupción, delitos que causen daño al patrimonio público y la administración pública; tráfico de drogas, legitimación de capitales, contra el sistema financiero y delitos conexos, delitos con multiplicidad de víctimas, delincuencia organizada, violaciones a los derechos humanos, lesa humanidad, delitos contra la independencia y seguridad de la nación y crímenes de guerra, el plazo prudencial al que se refiere el primer aparte del presente artículo, este lapso podrá ser hasta de seis meses.

`[ ] Es correcto`  `[ ] Es un error`

### copp · art. 324

**Error detectado:** …artar el ejercicio de la acusación ni el derecho a la defens ⟦a.T⟧ ambién podrá limitar el tiempo del uso de la palabra a quien…

**Texto completo:**

> El juez o jueza dirigirá el debate, ordenará la práctica de las pruebas, exigirá el cumplimiento de las solemnidades que correspondan, moderará la discusión y resolverá los incidentes y demás solicitudes de las partes. Impedirá que los alegatos se desvíen hacia aspectos inadmisibles o impertinentes, pero sin coartar el ejercicio de la acusación ni el derecho a la defensa.También podrá limitar el tiempo del uso de la palabra a quienes intervengan durante el juicio, fijando límites máximos igualitarios para todas las partes, o interrumpiendo a quien haga uso manifiestamente abusivo de su facultad.
> 
> Del mismo modo ejercerá las facultades disciplinarias destinadas a mantener el orden y decoro durante el debate y, en general, las necesarias para garantizar su eficaz realización.

`[ ] Es correcto`  `[ ] Es un error`

### copp · art. 373

**Error detectado:** …ra que se celebre dentro de los diez a quince días siguiente ⟦s.E⟧ n este caso, hasta cinco días antes de la audiencia de juici…

**Texto completo:**

> El aprehensor o aprehensora dentro de las doce horas siguientes a la detención, pondrá al aprehendido o aprehendida a la disposición del Ministerio Público, quien dentro de las treinta y seis horas siguientes, lo o la presentará ante el Juez o Jueza de Control competente a quien expondrá cómo se produjo la aprehensión, y según sea el caso, solicitará la aplicación del procedimiento ordinario o abreviado, y la imposición de una medida de coerción personal, o solicitará la libertad del aprehendido o aprehendida. En este último caso, sin perjuicio del ejercicio de las acciones a que hubiere lugar.
> 
> El Juez o Jueza de Control decidirá sobre la solicitud fiscal, dentro de las cuarenta y ocho horas siguientes desde que sea puesto el aprehendido o aprehendida a su disposición.
> 
> Si el Juez o Jueza de Control verifica que están dados los requisitos a que se refiere el artículo anterior, siempre que el o la Fiscal del Ministerio Público lo haya solicitado, decretará la aplicación del procedimiento abreviado, y remitirá las actuaciones al tribunal de juicio, el cual convocará directamente al juicio oral y público para que se celebre dentro de los diez a quince días siguientes.En este caso, hasta cinco días antes de la audiencia de juicio, el o la Fiscal y la víctima presentarán la acusación directamente en el tribunal del juicio, a los efectos que la defensa conozca los argumentos y prepare su defensa, y se seguirán, en lo demás, las reglas del procedimiento ordinario.
> 
> En caso contrario, el Juez o Jueza ordenará la aplicación del procedimiento ordinario y así lo hará constar en el acta que levantará al efecto.

`[ ] Es correcto`  `[ ] Es un error`

### copp · art. 387

**Error detectado:** …ncia y naturaleza del caso, la aprehensión de aquél o aquell ⟦a.U⟧ na vez aprehendido o aprehendida deberá ser presentado o pre…

**Texto completo:**

> Si la solicitud de extradición formulada por un gobierno extranjero se presenta sin la documentación judicial necesaria, pero con el ofrecimiento de producirla después, y con la petición de que mientras se produce se aprehenda al imputado o imputada, el tribunal de control, a solicitud del Ministerio Público, podrá ordenar, según la gravedad, urgencia y naturaleza del caso, la aprehensión de aquél o aquella.Una vez aprehendido o aprehendida deberá ser presentado o presentada dentro de las cuarenta y ocho horas siguientes ante el Juez o Jueza que ordenó su aprehensión, a los fines de ser informado o informada acerca de los motivos de su detención y de los derechos que le asisten.
> 
> El tribunal de control remitirá lo actuado al Tribunal Supremo de Justicia, que señalará el término perentorio para la presentación de la documentación, que no será mayor de sesenta días continuos.
> 
> El término perentorio de sesenta días se computará desde que conste en el respectivo expediente, la notificación hecha por el Ministerio con competencia en materia de relaciones exteriores, de la detención, al gobierno del país requirente.

`[ ] Es correcto`  `[ ] Es un error`

### copp · art. 441

**Error detectado:** …contesten dentro de tres días y, en su caso, promuevan prueb ⟦a.T⟧ ranscurrido dicho lapso, el Juez o Jueza, sin más trámite, d…

**Texto completo:**

> Presentado el recurso, el Juez o Jueza emplazará a las otras partes para que lo contesten dentro de tres días y, en su caso, promuevan prueba.Transcurrido dicho lapso, el Juez o Jueza, sin más trámite, dentro del plazo de veinticuatro horas, remitirá las actuaciones a la Corte de Apelaciones para que ésta decida.
> 
> Sólo se remitirá copia de las actuaciones pertinentes o se formará un cuaderno especial, para no demorar el procedimiento.
> 
> Excepcionalmente, la Corte de Apelaciones podrá solicitar otras copias o las actuaciones originales, sin que esto implique la paralización del procedimiento.

`[ ] Es correcto`  `[ ] Es un error`

### copp · art. 458

**Error detectado:** …ual, el Tribunal Supremo de Justicia dispondrá su utilizació ⟦n.E⟧ l secretario o secretaria, a solicitud del promovente, exped…

**Texto completo:**

> Si el Tribunal Supremo de Justicia considera que el recurso es admisible, convocará a una audiencia oral y pública que deberá realizarse dentro de un plazo no menor de quince días ni mayor de treinta.
> 
> El que haya promovido prueba tendrá la carga de su presentación en la audiencia, salvo que se trate del medio de reproducción a que se contrae el artículo 317 de este Código, caso en el cual, el Tribunal Supremo de Justicia dispondrá su utilización.El secretario o secretaria, a solicitud del promovente, expedirá las citaciones u órdenes que sean necesarias, las cuales serán diligenciadas por éste o ésta.
> 
> La prueba se recibirá conforme a las reglas del juicio oral, en lo pertinente.
> 
> La audiencia se celebrará con las partes que comparezcan. La palabra, para las conclusiones, será concedida primero al abogado del recurrente.
> 
> Se admitirá réplica y contrarréplica.El Tribunal Supremo de Justicia resolverá sobre el defecto de procedimiento, de ser el caso, únicamente con la prueba que se incorpore en la audiencia.
> 
> El Tribunal Supremo de Justicia decidirá al concluir la audiencia o, en caso de imposibilidad por la importancia y la complejidad de las cuestiones planteadas, dentro de los veinte días siguientes.

`[ ] Es correcto`  `[ ] Es un error`

### copp · art. 497

**Error detectado:** …ras que los internos o internas destinen al trabajo y estudi ⟦o.A⟧  los mismos efectos, los estudios que realice el penado o pe…

**Texto completo:**

> Sólo podrán ser considerados a los efectos de la redención de la pena de que trata la ley, el trabajo y el estudio, conjunta o alternativamente realizados dentro del centro de reclusión.
> 
> El trabajo necesario para la redención de la pena no podrá exceder de ocho horas diarias, realizado para empresas públicas o privadas, o entidades benéficas, todas debidamente acreditadas por el Ministerio con competencia penitenciaria, devengando el salario correspondiente. Cuando el interno o interna trabaje y estudie en forma simultánea, se le concederán las facilidades necesarias para la realización de los estudios, sin afectar la jornada de trabajo.
> 
> El trabajo y el estudio realizados deberán ser supervisados o verificados por el Ministerio con competencia penitenciaria y por el Juez o Jueza de ejecución. A tales fines, se llevará registro detallado de los días y horas que los internos o internas destinen al trabajo y estudio.A los mismos efectos, los estudios que realice el penado o penada, deberán estar comprendidos dentro de los programas establecidos por los Ministerios con competencia en las materias de Educación, Cultura y Deportes.

`[ ] Es correcto`  `[ ] Es un error`

### copp · art. Única

**Error detectado:** …en la Gaceta Oficial de la República Bolivariana de Venezuel ⟦a.D⟧ ada, firmada y sellada en el Palacio Federal Legislativo, se…

**Texto completo:**

> El presente Código entrará en vigencia a partir de su publicación en la Gaceta Oficial de la República Bolivariana de Venezuela.Dada, firmada y sellada en el Palacio Federal Legislativo, sede de la Asamblea Nacional de la República Bolivariana de Venezuela, en Caracas, a los dieciséis días del mes de septiembre de 2021. Años 211 de la Independencia, 162 de la Federación, y 22 de la Revolución Bolivariana-

`[ ] Es correcto`  `[ ] Es un error`

### crbv · art. 27

**Error detectado:** …tribunal lo tramitará con preferencia a cualquier otro asunt ⟦o.L⟧ a acción de amparo a la libertad o seguridad podrá ser inter…

**Texto completo:**

> Toda persona tiene derecho a ser amparada por los tribunales en el goce y ejercicio de los derechos y garantías constitucionales, aún de aquéllos inherentes a la persona que no figuren expresamente en esta Constitución o en los instrumentos internacionales sobre derechos humanos.
> 
> El procedimiento de la acción de amparo constitucional será oral, público, breve, gratuito y no sujeto a formalidad; y la autoridad judicial competente tendrá potestad para restablecer inmediatamente la situación jurídica infringida o la situación que más se asemeje a ella. Todo tiempo será hábil y el tribunal lo tramitará con preferencia a cualquier otro asunto.La acción de amparo a la libertad o seguridad podrá ser interpuesta por cualquier persona; y el detenido o detenida será puesto o puesta bajo la custodia del tribunal de manera inmediata, sin dilación alguna.
> 
> El ejercicio de este derecho no puede ser afectado, en modo alguno, por la declaración del estado de excepción o de la restricción de garantías constitucionales.

`[ ] Es correcto`  `[ ] Es un error`

### crbv · art. 60

**Error detectado:** …vada, intimidad, propia imagen, confidencialidad y reputació ⟦n.L⟧ a ley limitará el uso de la informática para garantizar el h…

**Texto completo:**

> Toda persona tiene derecho a la protección de su honor, vida privada, intimidad, propia imagen, confidencialidad y reputación.La ley limitará el uso de la informática para garantizar el honor y la intimidad personal y familiar de los ciudadanos y ciudadanas y el pleno ejercicio de sus derechos.

`[ ] Es correcto`  `[ ] Es un error`

### crbv · art. 276

**Error detectado:** …alquier momento les sean solicitados por la Asamblea Naciona ⟦l.T⟧ anto los informes ordinarios como los extraordinarios se pub…

**Texto completo:**

> El Presidente o Presidenta del Consejo Moral Republicano y los o las titulares de los órganos del Poder Ciudadano presentarán un informe anual ante la Asamblea Nacional en sesión plenaria. Así mismo, presentará los informes que en cualquier momento les sean solicitados por la Asamblea Nacional.Tanto los informes ordinarios como los extraordinarios se publicarán.

`[ ] Es correcto`  `[ ] Es un error`

### crbv · art. 284

**Error detectado:** …xilio de los funcionarios o funcionarias que determine la le ⟦y.P⟧ ara ser Fiscal General de la República se requieren las mism…

**Texto completo:**

> El Ministerio Público estará bajo la dirección y responsabilidad del Fiscal o la Fiscal General de la República, quien ejercerá sus atribuciones directamente con el auxilio de los funcionarios o funcionarias que determine la ley.Para ser Fiscal General de la República se requieren las mismas condiciones de elegibilidad de los magistrados o magistradas del Tribunal Supremo de Justicia. El Fiscal o la Fiscal General de la República será designado o designada para un período de siete años.

`[ ] Es correcto`  `[ ] Es un error`

### crbv · art. 349

**Error detectado:** …identa de la República no podrá objetar la nueva Constitució ⟦n.L⟧ os poderes constituidos no podrán en forma alguna impedir la…

**Texto completo:**

> El Presidente o Presidenta de la República no podrá objetar la nueva Constitución.Los poderes constituidos no podrán en forma alguna impedir las decisiones de la Asamblea Nacional Constituyente.
> 
> Una vez promulgada la nueva Constitución, ésta se publicada en la Gaceta Oficial de la República Bolivariana de Venezuela o en la Gaceta de la Asamblea Nacional Constituyente.

`[ ] Es correcto`  `[ ] Es un error`

### crbv · art. Novena

**Error detectado:** …omo bases las atribuciones que le establece esta Constitució ⟦n.D⟧ écima. Lo dispuesto en el numeral 4 del artículo 167 de esta…

**Texto completo:**

> Mientras no se dicten las leyes relativas al Capítulo IV del Título V de esta Constitución, se mantendrán en vigencia las Leyes Orgánicas del Ministerio Público y de la Contraloría General de la República. En cuanto a la Defensoría del Pueblo, el o la titular será designado o designada de manera provisoria por la Asamblea Nacional Constituyente. El Defensor o Defensora del Pueblo adelantará lo correspondiente a la estructura organizativa, integración, establecimiento de presupuesto e infraestructura física, tomando como bases las atribuciones que le establece esta Constitución.Décima. Lo dispuesto en el numeral 4 del artículo 167 de esta Constitución sobre la obligación que tienen los Estados de designar un mínimo del cincuenta por ciento del situado constitucional a la inversión, entrará en vigencia a partir del primero de enero del año dos mil uno.
> 
> Decimoprimera. Hasta tanto se dicte la legislación nacional relativa al régimen de las tierras baldías, la administración de las mismas continuará siendo ejercida por el Poder Nacional, conforme a la legislación vigente.
> 
> Decimosegunda. La demarcación del hábitat indígena a que se refiere el artículo 119 de esta Constitución, se realizará dentro del lapso de dos años contados a partir de la fecha de entrada en vigencia de esta Constitución.
> 
> Decimotercera. Hasta tanto los Estados, asuman por ley estadal las competencias referidas en el numeral 7 del artículo 164 de esta Constitución, se mantendrá el régimen vigente.
> 
> Decimocuarta. Mientras no se dicte la legislación que desarrolle los principios de esta Constitución sobre el régimen municipal, continuarán plenamente vigentes las ordenanzas y demás instrumentos normativos de los Municipios, relativos a las materias de su competencia y al ámbito fiscal propio, que tienen atribuido conforme al ordenamiento jurídico aplicable antes de la sanción de esta Constitución.
> 
> Decimoquinta. Hasta tanto se apruebe la legislación a que se refiere el artículo 105 de esta Constitución, se mantendrá en vigencia el ordenamiento jurídico aplicable antes de la sanción de esta Constitución.
> 
> Decimosexta. Para el enriquecimiento del acervo histórico de la Nación, el cronista de la Asamblea Nacional Constituyente coordinará lo necesario para salvaguardar las grabaciones o registros que de las secciones y actividades de la Asamblea Nacional Constituyente se realizaron en imagen, en sonido; en documentos escritos, digitales, fotográficos o hemerográficos; en cualquier otra forma de documento elaborado.
> 
> Todos estos documentos quedarán bajo la protección del Archivo General de la Nación.
> 
> Decimoséptima. El nombre de la República, una vez aprobada esta Constitución será "República Bolivariana de Venezuela", tal como está previsto en su artículo uno. Es obligación de las autoridades e instituciones, tanto públicas como privadas, que deban expedir registros, títulos o cualquier otro documento, utilizar el nombre de "República Bolivariana de Venezuela", de manera inmediata.
> 
> En trámites rutinarios las dependencias administrativas agotarán el inventario documental de papelería; su renovación se hará progresivamente con la mencionada denominación, en un plazo que no excederá de cinco años.
> 
> La circulación de monedas acuñadas y billetes emitidos con el nombre de "República de Venezuela", estará regulada por la Reforma de la Ley del Banco Central de Venezuela contemplada en la Disposición Transitoria cuarta de esta Constitución, en función de hacer la transición a la denominación "República Bolivariana de Venezuela".
> 
> Decimoctava. A los fines de asegurar la vigencia de los principios establecidos en el artículo 113 de esta Constitución, la Asamblea Nacional dictará una ley que establezca, entre otros aspectos el organismo de supervisión, control y fiscalización que deba asegurar la efectiva aplicación de estos principios y las disposiciones y demás reglas que los desarrolle.
> 
> La persona que presida o dirija este organismo será designada por el voto de la mayoría de los diputados o diputadas a la Asamblea Nacional, previo informe favorable de una comisión especial designada de su seno al efecto.
> 
> La ley establecerá que los funcionarios o funcionarias de la Administración Pública y los jueces o juezas llamados o llamadas a conocer y decidir las controversias relacionadas con las materias a que se refiere el artículo 113 de esta Constitución, observen, con carácter prioritario y excluyente, los principios allí definidos, y se abstengan de aplicar cualquier disposición susceptible de generar efectos contrarios a ellos.
> 
> La ley establecerá en las concesiones de servicios públicos, la utilidad para el concesionario o concesionaria y el financiamiento de las inversiones estrictamente vinculadas a la prestación del servicio, incluyendo las mejora y ampliaciones que la autoridad competente considere razonables y apruebe en cada caso.

`[ ] Es correcto`  `[ ] Es un error`

### ley-contra-la-estafa-inmobiliaria · art. 18

**Error detectado:** …a o preventa, decidan rescindir los contratos unilateralment ⟦e.C⟧ ualquier estipulación en contrario es nula, con la excepción…

**Texto completo:**

> Artículo 18. No podrá, ni es válido que los constructores, contratistas, productores y promotores de viviendas, ofrecidas y contratadas en venta o preventa, decidan rescindir los contratos unilateralmente.Cualquier estipulación en contrario es nula, con la excepción que se produzca el incumplimiento o falta de pago por más de noventa días de cualquiera de las cuotas previstas en el contrato, por causas atribuibles al comprador. La solicitud de rescisión debe ser avalada por la Dirección General de Gestión del Sistema Nacional de Vivienda y Hábitat.

`[ ] Es correcto`  `[ ] Es un error`

### ley-contra-la-estafa-inmobiliaria · art. 36

**Error detectado:** …te período podrá extenderse a quince días hábiles adicionale ⟦s.L⟧ os funcionarios o funcionarias que certifiquen el permiso si…

**Texto completo:**

> Artículo 36. El constructor, contratista, productor y promotor de viviendas, debe consignar ante el órgano competente de la municipalidad respectiva, el proyecto conjuntamente con los estudios especiales y técnicos del urbanismo o edificación, para la solicitud de la solvencia municipal y el permiso para la construcción de la obra.
> 
> El proyecto debe cumplir con la obligatoriedad de presentar todos los estudios realizados previamente, antes de otorgar el respectivo permiso de construcción. Estos estudios debes ser: impacto ambiental, impacto vial, capacidad y factibilidad de los colectores de aguas servidas y drenajes, suministro de agua potable, suministro de electricidad, suministro de gas doméstico y servicio de telecomunicaciones. Estos estudios deben soportar toda la nueva demanda demográfica, que se producirá en el sector y se adicionará a los existentes.
> 
> Igualmente, se debe consignar el respectivo estudio de suelos, incluyendo la toma de muestras en todas las áreas del terreno sobre el cual se realizará la construcción. Las muestras de suelo, deben ser tomadas a distancias hasta cincuenta metros (50 m) entre una y otra, de lo contrario el estudio no tendrá validez técnica y será nulo.
> 
> La oficina de la municipalidad competente debe entregar al constructor, contratista, productor y promotor de viviendas, en un lapso no mayor de treinta días hábiles, la solvencia municipal y la certificación de permiso para el inicio de la obra. En caso de que exista alguna corrección y ajuste al proyecto, este período podrá extenderse a quince días hábiles adicionales.Los funcionarios o funcionarias que certifiquen el permiso sin el cumplimiento de lo estipulado en el presente artículo, serán sancionados o sancionadas penal, civil y administrativamente.
> 
> Asimismo, el constructor, contratista, productor y promotor de viviendas, debe realizar los pagos correspondientes a las tasas administrativas.

`[ ] Es correcto`  `[ ] Es un error`

### ley-organica-contra-la-delincuencia-organizada-y-financiamiento-al-terrorismo · art. 35

**Error detectado:** …nte al valor del incremento patrimonial ilícitamente obtenid ⟦o.L⟧ a misma pena se aplicará a quien por sí o por interpuesta pe…

**Texto completo:**

> Quien por sí o por interpuesta persona sea propietario o propietaria, poseedor o poseedora de capitales, bienes, fondos, haberes o beneficios, a sabiendas de que provienen directa o indirectamente de una actividad ilícita, será penado o penada con prisión de diez a quince años y multa equivalente al valor del incremento patrimonial ilícitamente obtenido.La misma pena se aplicará a quien por sí o por interpuesta persona realice las actividades siguientes:
> 
> 1.- La conversión, transferencia o traslado por cualquier medio de bienes, capitales, haberes, beneficios o excedentes con el objeto de ocultar o encubrir el origen ilícito de tos mismos o de ayudar a cualquier persona que participe en la comisión de tales delitos a eludir las consecuencias jurídicas de sus acciones.
> 
> 2.- El ocultamiento, encubrimiento o simulación de la naturaleza, origen, ubicación, disposición, destino, movimiento o propiedad de bienes o del legítimo derecho de éstos.
> 
> 3.- La adquisición, posesión o la utilización de bienes producto de algún delito.
> 
> 4.- El resguardo, inversión, transformación, custodia o administración de bienes o capitales provenientes de actividades ilícitas.
> 
> Los capitales, bienes o haberes objeto del delito de legitimación de capitales serán decomisados o confiscados.

`[ ] Es correcto`  `[ ] Es un error`

### ley-organica-contra-la-delincuencia-organizada-y-financiamiento-al-terrorismo · art. 58

**Error detectado:** …no anterior. Esta incidencia no interrumpirá el proceso pena ⟦l.E⟧ n caso de haberse promovido medios probatorios, el juez o ju…

**Texto completo:**

> Transcurrido un año desde que se practicó la incautación preventiva sin que haya sido posible establecer la identidad del titular del bien, autor o partícipe del hecho, o éste lo ha abandonado, el o la fiscal del Ministerio Público solicitará al tribunal de control su decomiso. A tales fines, el tribunal de control ordenará al órgano rector que notifique mediante un cartel publicado en un diario de circulación nacional, el cual indicará las causas de la notificación, procediendo a consignar en el expediente respectivo la página en la cual fue publicado el cartel.
> 
> Dentro de los treinta días siguientes a la publicación del cartel, los legítimos interesados deberán consignar ante el citado tribunal de control, escrito debidamente fundado y promover los medios probatorios que justifiquen el derecho invocado. Transcurrido el referido lapso, sin que los legítimos interesados hayan hecho oposición alguna, el juez o jueza decretará el decomiso del bien.
> 
> Si existe oposición, el juez o jueza notificará al o la fiscal del Ministerio Público, para que dentro de los cinco días siguientes a la notificación, conteste y consigne pruebas. Si no se ha presentado medio probatorio alguno o si el punto es de mero derecho, el juez o jueza decidirá sin más trámites de manera motivada dentro de los tres días siguientes al vencimiento del término anterior. Esta incidencia no interrumpirá el proceso penal.En caso de haberse promovido medios probatorios, el juez o jueza convocarán a una audiencia oral, que se celebrará dentro de los ocho días siguientes a la publicación del auto respectivo. En la audiencia el o la fiscal del Ministerio Público y el legítimo interesado, expondrán oralmente sus alegatos y presentarán sus pruebas. Al término de la audiencia el juez o jueza decidirá de manera motivada. La decisión que dicte el juez o jueza es apelable por las partes, dentro de los cinco días siguientes.
> 
> Si el legítimo interesado no se presenta a la audiencia convocada por el tribunal, sin causa debidamente justificada, se declarará desistida su oposición y se decretará el decomiso del bien. Contra dicha decisión no se admitirá recurso alguno.
> 
> Cuando la decisión del tribunal de control mediante la cual decreta el decomiso, se encuentre definitivamente firme, el bien pasará a la orden del órgano rector o al Servicio Especializado para la Administración y Enajenación de Bienes Asegurados o Incautados, Decomisados y Confiscados.

`[ ] Es correcto`  `[ ] Es un error`

### ley-organica-contra-la-delincuencia-organizada-y-financiamiento-al-terrorismo · art. Segunda

**Error detectado:** …s siguientes a la entrada en vigencia del decreto de creació ⟦n.S⟧ e exceptúa al Servicio Especializado para la Administración …

**Texto completo:**

> El Ministerio del Poder Popular con competencia en materia de interior y justicia conjuntamente con la Oficina Nacional Contra la Delincuencia Organizada y Financiamiento al Terrorismo, quedan encargados de la implementación y funcionamiento del Servicio Especializado para la Administración y Enajenación de Bienes Asegurados o Incautados, Decomisados y Confiscados.
> 
> El servicio deberá integrarse e iniciar sus funciones dentro de los doce meses siguientes a la entrada en vigencia del decreto de creación.Se exceptúa al Servicio Especializado para la Administración y Enajenación de Bienes Asegurados o Incautados, Decomisados y Confiscados de la aplicación de las disposiciones contenidas en la ley orgánica que regula la enajenación de bienes del sector público no afectos a las industrias básicas.
> 
> El proceso de transferencia de los bienes puestos a la orden del órgano rector a que se refiere la presente Ley, se realizará al entrar en pleno funcionamiento el referido servicio.

`[ ] Es correcto`  `[ ] Es un error`

### ley-organica-de-amparo-sobre-derechos-y-garantias-constitucionales · art. 13

**Error detectado:** …uradores de Menores, Agrarios y del Trabajo, si fuere el cas ⟦o.T⟧ odo el tiempo será hábil y el Tribunal dará preferencia al t…

**Texto completo:**

> Artículo 13.- La acción de amparo constitucional puede ser interpuesta ante el Juez competente por cualquier persona natural o jurídica, por representación o directamente, quedando a salvo las atribuciones del Ministerio Público, y de los Procuradores de Menores, Agrarios y del Trabajo, si fuere el caso.Todo el tiempo será hábil y el Tribunal dará preferencia al trámite de amparo sobre cualquier otro asunto.

`[ ] Es correcto`  `[ ] Es un error`

### ley-organica-de-la-defensa-publica · art. 29

**Error detectado:** … que también estuviere incurso en alguna causal de inhibició ⟦n.N⟧ o podrá obligarse a la Defensora Pública o Defensor Público …

**Texto completo:**

> En caso de inhibición la funcionaria o funcionario expondrá por diligencia las razones de hecho y de derecho que las justifiquen ante la Coordinadora o Coordinador Regional, quien a su vez lo participará a la Defensora Pública General o Defensor Público General de la Defensa Pública, correspondiéndole a la Coordinadora o Coordinador Regional la designación de otra Defensora Pública u otro Defensor Público. La designada o designado sustituirá a la inhibida o inhibido, a menos que también estuviere incurso en alguna causal de inhibición.No podrá obligarse a la Defensora Pública o Defensor Público inhibido o inhibida a continuar interviniendo en el proceso. Quedan a salvo las sanciones a que diere lugar su conducta.

`[ ] Es correcto`  `[ ] Es un error`

### ley-organica-del-ministerio-publico · art. 36

**Error detectado:** … participación en procesos judiciales de cualquier naturalez ⟦a.E⟧ n cada Circuito Judicial Penal existirán los Fiscales de Pro…

**Texto completo:**

> Son Fiscales del Ministerio Público de Proceso, aquellos o aquellas que en esta Ley, el Código Orgánico Procesal Penal y demás leyes tengan atribuida participación en procesos judiciales de cualquier naturaleza.En cada Circuito Judicial Penal existirán los Fiscales de Proceso que sean indispensables para el cumplimiento de las funciones del Ministerio Público.
> 
> Atribuciones y deberes

`[ ] Es correcto`  `[ ] Es un error`

### ley-organica-del-ministerio-publico · art. 83

**Error detectado:** …es serán otorgadas por el director o directora de adscripció ⟦n.S⟧ i se ausentaren sin existir alguna de las circunstancias ant…

**Texto completo:**

> Los fiscales o las fiscales del Ministerio Público residirán en el lugar del ejercicio de sus atribuciones o en el área suburbana inmediata.
> 
> Sólo podrán ausentarse por algunas de las causales constitutivas de faltas temporales, conforme al artículo 57 de esta Ley y por razones de servicio debidamente justificadas y autorizadas por el Fiscal o la Fiscal Superior. Las autorizaciones que al respecto requieran los fiscales o las fiscales superiores serán otorgadas por el director o directora de adscripción.Si se ausentaren sin existir alguna de las circunstancias anteriores, podrán ser sancionados o sancionadas disciplinariamente por el Fiscal o la Fiscal General de la República, o quien haga sus veces, de conformidad con lo dispuesto en el Título IX de esta Ley.

`[ ] Es correcto`  `[ ] Es un error`

### ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes · art. 98

**Error detectado:** …ecto, el Consejo de Protección de Niños, Niñas y Adolescente ⟦s.P⟧ arágrafo Primero. Este Registro contendrá:

**Texto completo:**

> Para trabajar, todos los y las adolescentes deben inscribirse en el Registro de Adolescentes Trabajadores y Trabajadoras, que llevará, a tal efecto, el Consejo de Protección de Niños, Niñas y Adolescentes.Parágrafo Primero. Este Registro contendrá:

`[ ] Es correcto`  `[ ] Es un error`

### ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes · art. 355

**Error detectado:** … la responsabilidad de crianza del hijo o hija, según el cas ⟦o.L⟧ a solicitud de restitución de la patria potestad debe estar …

**Texto completo:**

> El padre o la madre privados de la Patria Potestad pueden solicitar que se le restituya, después de dos años de la sentencia firme que la decretó. La solicitud debe ser notificada al Ministerio Público y, de ser el caso, a la persona que interpuso la acción de privación o al consejo de protección de niños, niñas y adolescentes. El juez o jueza, para evaluar la conveniencia de la restitución de la Patria Potestad, debe oír la opinión del hijo o hija, la del otro padre o madre que la ejerza y la de la persona que tenga la responsabilidad de crianza del hijo o hija, según el caso.La solicitud de restitución de la patria potestad debe estar fundada en la prueba de haber cesado la causal o causales que motivaron la privación.

`[ ] Es correcto`  `[ ] Es un error`

### ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes · art. 451

**Error detectado:** …o el otorgamiento del mandato para su representación judicia ⟦l.E⟧ n aquellos procesos iniciados por los y las adolescentes, su…

**Texto completo:**

> Los y las adolescentes tienen plena capacidad en todos los procesos para ejercer las acciones dirigidas a la defensa de aquellos derechos e intereses en los cuales la ley les reconoce capacidad de ejercicio, en consecuencia, pueden realizar de forma personal y directa actos procesales válidos, incluyendo el otorgamiento del mandato para su representación judicial.En aquellos procesos iniciados por los y las adolescentes, sus padres, madres, representantes o responsables pueden intervenir como terceros interesados.

`[ ] Es correcto`  `[ ] Es un error`

### ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes · art. 617

**Error detectado:** …ación inmediata. Si ésta no se lograre se ordenará su captur ⟦a.L⟧ ograda la ubicación o la captura, el juez o la jueza compete…

**Texto completo:**

> El o la adolescente que se evada de la entidad de atención donde esté detenido o detenida, se ausente indebidamente del lugar asignado para su residencia o que sin grave y legítimo impedimento no asista al programa al que se le ha ordenado incorporarse, o no comparezca a la audiencia preliminar, al juicio, o ante el tribunal de ejecución, será declarado o declarada en rebeldía y se ordenará su ubicación inmediata. Si ésta no se lograre se ordenará su captura.Lograda la ubicación o la captura, el juez o la jueza competente, según la fase, tomará las medidas de aseguramiento necesarias.

`[ ] Es correcto`  `[ ] Es un error`


## Minúscula después de punto

### codigo-organico-de-justicia-militar · art. 48

**Error detectado:** …eran las necesidades del buen servicio de la Justicia Milita ⟦r. y⟧  las jurisdicciones territoriales respectivas de cada uno de…

**Texto completo:**

> Los Jueces Militares de Primera Instancia Permanentes funcionarán en los lugares donde a juicio del Presidente de la República los requieran las necesidades del buen servicio de la Justicia Militar. y las jurisdicciones territoriales respectivas de cada uno de ellos.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-organico-de-justicia-militar · art. 54

**Error detectado:** Son atribuciones del Presidente de la Repúblic ⟦a. c⟧ omo funcionario de justicia militar:

**Texto completo:**

> Son atribuciones del Presidente de la República. como funcionario de justicia militar:

`[ ] Es correcto`  `[ ] Es un error`

### codigo-organico-de-justicia-militar · art. 121

**Error detectado:** Ningún juez inhibido podrá ser allanado por la parte fisca ⟦l. p⟧ or el reo, su defensor o por el acusador.

**Texto completo:**

> Ningún juez inhibido podrá ser allanado por la parte fiscal. por el reo, su defensor o por el acusador.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-organico-de-justicia-militar · art. 170

**Error detectado:** Toda persona debe denunciar ante las autoridades militare ⟦s. p⟧ oliciales o judiciales la preparación o comisión de los deli…

**Texto completo:**

> Toda persona debe denunciar ante las autoridades militares. policiales o judiciales la preparación o comisión de los delitos militares de que tenga conocimiento.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-organico-de-justicia-militar · art. 215

**Error detectado:** … aún se negare a contestar, le tomará sus señales fisonómica ⟦s. a⟧  objeto de identificarlo.

**Texto completo:**

> Si el reo se negare a contestar las preguntas indicadas en el artículo 213, el Juez lo interrogará sobre sus características personales y el empleo de su tiempo en el momento de la consumación del delito; y si aún se negare a contestar, le tomará sus señales fisonómicas. a objeto de identificarlo.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-organico-de-justicia-militar · art. 274

**Error detectado:** …sa, harán prueba plena sobre la materia a que se contraigan  ⟦y. p⟧ odrán ser presentados en la misma oportunidad que los docume…

**Texto completo:**

> Los registros militares, órdenes generales, croquis, planos y documentos o certificados expedidos por el Ministro de la Defensa, harán prueba plena sobre la materia a que se contraigan y. podrán ser presentados en la misma oportunidad que los documentos públicos.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-organico-de-justicia-militar · art. 308

**Error detectado:** …uevamente nombrados se enterarán de los resultados anteriore ⟦s. y⟧  con estos datos emitirán su juicio razonado.

**Texto completo:**

> Cada vez que sea necesario, a juicio del Tribunal, se aumentará el número de peritos, y así se hará indispensablemente siempre en número impar, cuando siendo dos los que hayan procedido, estuvieren discordes en su informe.
> 
> En tal caso practicarán todos nuevas operaciones y, no siendo esto posible, los nuevamente nombrados se enterarán de los resultados anteriores. y con estos datos emitirán su juicio razonado.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-organico-de-justicia-militar · art. 313

**Error detectado:** …oncederá a las partes que lo soliciten, el derecho de réplic ⟦a. p⟧ or una sola vez en el mismo acto de informes y por el tiempo…

**Texto completo:**

> Terminada la relación, el Tribunal fijará la audiencia siguiente para oír en un solo acto los informes de las partes y recibir sus conclusiones escritas, las cuales serán agregadas al expediente.
> 
> El Tribunal concederá a las partes que lo soliciten, el derecho de réplica. por una sola vez en el mismo acto de informes y por el tiempo que previamente señale el Tribunal.
> 
> Si se agotaren las horas de audiencia sin haber concluido los informes réplica y contra-réplica, el Tribunal la prorrogará por el tiempo necesario.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-organico-de-justicia-militar · art. 358

**Error detectado:** …á en el mismo acto el Consejo de Guerra respectivo, el Fisca ⟦l. y⟧  un Auditor, si no lo hubiere.

**Texto completo:**

> Al llegar a conocimiento del Jefe Superior de una fuerza independiente en estado de guerra la comisión de un delito militar, dictará auto de detención, ordenará el enjuiciamiento y nombrará en el mismo acto el Consejo de Guerra respectivo, el Fiscal. y un Auditor, si no lo hubiere.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-organico-de-justicia-militar · art. 364

**Error detectado:** Oídos los testigos y los peritos por el Consejo de Guerr ⟦a. p⟧ odrán interrogarlos el Auditor, el Fiscal y el defensor. Tan…

**Texto completo:**

> Oídos los testigos y los peritos por el Consejo de Guerra. podrán interrogarlos el Auditor, el Fiscal y el defensor. Tanto las preguntas como las contestaciones serán escritas en el expediente y el Presidente deberá aclarar al declarante los puntos que no entienda y defender su testimonio.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-organico-de-justicia-militar · art. 401

**Error detectado:** …onaje, así como tampoco en los casos de rebelión, sublevació ⟦n. m⟧ otín, insubordinación armada, deserción en campaña, abandono…

**Texto completo:**

> No se tomará en cuenta circunstancia atenuante alguna, en los casos de traición a la patria o espionaje, así como tampoco en los casos de rebelión, sublevación. motín, insubordinación armada, deserción en campaña, abandono del puesto de centinela frente al enemigo, y en general, cuando se trate de delitos que, según las circunstancias en que ocurrieren, pusieren en peligro la existencia de una fuerza armada.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-organico-de-justicia-militar · art. 552

**Error detectado:** … años.

En la misma pena incurrirá el que inutilice las arma ⟦s. v⟧ alores o útiles pertenecientes a las Fuerzas Armadas, si con…

**Texto completo:**

> El que por cualquier medio destruya fortalezas, naves, aeronaves, cuarteles, arsenales u otras dependencias militares o navales, será penado con presidio de ocho a dieciséis años.
> 
> En la misma pena incurrirá el que inutilice las armas. valores o útiles pertenecientes a las Fuerzas Armadas, si con ello se le hubiere ocasionado grave daño.

`[ ] Es correcto`  `[ ] Es un error`

### codigo-organico-de-justicia-militar · art. 557

**Error detectado:** …centración donde se encuentren presos militares o prisionero ⟦s. c⟧ on el ánimo de favorecer su fuga, será penado con presidio d…

**Texto completo:**

> El militar que ataque a mano armada cualquier edificio o campo de concentración donde se encuentren presos militares o prisioneros. con el ánimo de favorecer su fuga, será penado con presidio de seis a ocho años. Si la fuga se verifica, la pena será de diez a doce años de presidio.

`[ ] Es correcto`  `[ ] Es un error`

### ley-de-carrera-judicial · art. 20

**Error detectado:** …an los requisitos establecidos en esta Ley para los traslado ⟦s.

d⟧ e los anteriores, los Jueces del mismo circuito o región que…

**Texto completo:**

> Para la provisión de los cargos vacantes y de los que se crearen conforme a la Ley, tendrán preferencia en orden de prelación, los funcionarios que se indican a continuación:
> 
> Jueces de Circunscripciones Judiciales diferentes pero de la misma categoría del que debe ser provisto, que soliciten el traslado al circuito y reúnan los requisitos establecidos en esta Ley para los traslados.
> 
> de los anteriores, los Jueces del mismo circuito o región que hayan servido en la Categoría inmediatamente inferior a la del cargo que debe llenarse, y que reúnan las condiciones establecidas en esta Ley para los ascensos.
> 
> Suplentes del Titular que haya de ser suplido, designados conforme a lo previsto en el artículo 22.
> 
> Cuando sean más de uno de los Jueces comprendidos en la preferencia de que trata este artículo, el Consejo de la Judicatura sacará a concurso la provisión del cargo entre los Jueces interesados.

`[ ] Es correcto`  `[ ] Es un error`

### ley-de-carrera-judicial · art. 28

**Error detectado:** …uncionario y compensación económica de los gastos de traslad ⟦o.

s⟧ olicitarlo así el interesado, y si a juicio del Consejo de l…

**Texto completo:**

> Los Jueces podrán ser trasladados dentro de una misma región o a una región diferente, a cargo de la misma Categoría y competencia, por las causas siguientes:
> 
> razones de servicio, calificadas mediante resolución motivada del Consejo de la Judicatura, previa audiencia y aceptación del funcionario y compensación económica de los gastos de traslado.
> 
> solicitarlo así el interesado, y si a juicio del Consejo de la Judicatura aquél haya acumulado méritos en el ejercicio del cargo, tenga una causa justificada y el traslado no sea inconveniente para el servicio de la administración de justicia.
> 
> casos de preferencia a que se refiere el ordinal 1 del artículo 20 de esta Ley.
> 
> El traslado a una Categoría inferior o de competencia diferente, sólo podrá hacerse a solicitud del interesado.

`[ ] Es correcto`  `[ ] Es un error`

### ley-de-carrera-judicial · art. 38

**Error detectado:** …o vías de hecho a sus superiores o a sus iguales o inferiore ⟦s.

t⟧ raspasen los límites racionales de su autoridad respecto a s…

**Texto completo:**

> Los Jueces podrán ser amonestados por las causas siguientes:
> 
> ofendieren de palabra, por escrito o vías de hecho a sus superiores o a sus iguales o inferiores.
> 
> traspasen los límites racionales de su autoridad respecto a sus auxiliares y subalternos; a los que acudan a ellos en asuntos de justicia; o a los que asistan a estrados, cualquiera que sea el objeto con que lo hagan.
> 
> embriaguen en lugares expuestos a la vista del público.
> 
> dejen de dar audiencia o despachar sin causa justificada o incumplan el horario establecido.
> 
> ausenten del lugar donde ejerzan sus funciones en tiempo hábil y en forma injustificada, sin la licencia respectiva.
> 
> sea llevado en forma regular el libro Diario del Tribunal.
> 
> incurran en retrasos y descuidos injustificados en la tramitación de los procesos o de cualquier diligencia en los mismos.
> 
> Los Jueces que conozcan en grado de una causa están en la obligación de amonestar de oficio al inferior, cuando observaren los retrasos y descuidos a los que se refiere el ordinal 7 de este artículo y de enviar al Consejo de la Judicatura copia de la decisión que se agregará al expediente del Juez. El incumplimiento de este deber por parte de los Jueces que conocen en grado de una causa, será motivo de amonestación por parte del Consejo de la Judicatura.

`[ ] Es correcto`  `[ ] Es un error`

### ley-de-carrera-judicial · art. 39

**Error detectado:** …n tela de juicio el decoro o la imparcialidad del funcionari ⟦o.

c⟧ ontraigan obligaciones que den lugar a reclamaciones judicia…

**Texto completo:**

> Los Jueces serán suspendidos de sus cargos por las causas siguientes:
> 
> soliciten préstamos en dinero o en efectos, u otros favores o servicios, que por su frecuencia u otras circunstancias, pongan en tela de juicio el decoro o la imparcialidad del funcionario.
> 
> contraigan obligaciones que den lugar a reclamaciones judiciales en las que fueren declarados responsables.
> 
> den el rendimiento satisfactorio anual, evaluado como se indica en el artículo 32 de esta Ley.
> 
> sean reincidentes en los retrasos y descuidos a que se refiere el ordinal 7 del artículo 38 de esta Ley.
> 
> observen una conducta censurable que comprometa la dignidad del cargo o le hagan desmerecer en el concepto público.
> 
> incurran en nueva infracción después de haber sufrido dos amonestaciones en un año.
> 
> observen la exactitud de los plazos y términos judiciales a que están sujetos conforme a las leyes, o difieran las sentencias sin causa justificada.
> 
> hicieren el nombramiento de depositarios en la forma señalada por la ley.
> 
> abstengan de decidir so pretexto de silencio, contradicción o deficiencia de la Ley, de oscuridad en sus términos, o cuando retardaren ilegalmente dictar alguna medida, providencia, decreto, decisión o sentencia, aunque no se hubiere interpuesto por estos motivos la queja para hacer efectiva la responsabilidad civil ni la acción penal correspondiente a la denegación de justicia.
> 
> La suspensión será por un tiempo de tres meses a un año a juicio del Consejo de la Judicatura y según la gravedad de la falta.

`[ ] Es correcto`  `[ ] Es un error`

### ley-del-estatuto-de-la-funcion-de-la-policia-de-investigacion · art. 29

**Error detectado:** …un sistema fundamentado en criterios de eficacia y eficienci ⟦a. l⟧ a Inspectoría General implementará, como parte del protocolo…

**Texto completo:**

> El desempeño de las funcionarias y funcionarios policiales de investigación se evaluará de manera individual y en equipos de trabajo, a través de un sistema fundamentado en criterios de eficacia y eficiencia. la Inspectoría General implementará, como parte del protocolo de supervisión continua e intervención temprana, y de conformidad con los indicadores que establezcan los reglamentos y resoluciones de esta Ley, un sistema que permita registrar el seguimiento de las actividades de las funcionarias y funcionarios policiales de investigación y los informes de supervisión correspondientes, a fin de incorporarlo en el historial personal y un sistema de puntaje que permita calibrar los logros y avances de cada funcionaria o funcionario policial en su carrera de una forma objetiva, imparcial e integral.

`[ ] Es correcto`  `[ ] Es un error`

### ley-del-estatuto-de-la-funcion-de-la-policia-de-investigacion · art. 30

**Error detectado:** …der Popular con competencia en materia de seguridad ciudadan ⟦a. l⟧ a organización y regulaciones del historial personal se rige…

**Texto completo:**

> Todas las funcionarias y funcionarios policiales de investigación tendrán un historial personal contentivo de la documentación relacionada con su carrera policial, que permita un conocimiento de su situación personal, familiar y socioeconómica, así como de su evaluación integral y continua. El historial personal será de manejo confidencial, al cual sólo tiene acceso la funcionaria o funcionario policial a quien se refiere y las autoridades competentes.
> 
> La oficina de recursos humanos del Cuerpo de Investigaciones Científicas, Penales y Criminalísticas debe llevar y mantener actualizado el historial personal de todos los funcionarios y funcionarias policiales de investigación que presten servicio. Copia de este historial personal deberá ser presentada anualmente al Ministerio del Poder Popular con competencia en materia de seguridad ciudadana. la organización y regulaciones del historial personal se rigen de conformidad con lo previsto en la presente Ley, sus reglamentos y resoluciones.

`[ ] Es correcto`  `[ ] Es un error`

### ley-del-estatuto-de-la-funcion-de-la-policia-de-investigacion · art. 76

**Error detectado:** … los procedimientos y las reglas previstas en la presente Le ⟦y. l⟧ a integración, organización y funcionamiento del Consejo Dis…

**Texto completo:**

> El Consejo Disciplinario de Policía de Investigación estará integrado por tres personas, dos de libre nombramiento y remoción del órgano rector y una de libre nombramiento y remoción de la Directora o Director del Cuerpo de Investigaciones Científicas, Penales y Criminalísticas. Estas designaciones deberán ser publicadas en la Gaceta Oficial de la República Bolivariana de Venezuela.
> 
> El Consejo Disciplinario de Policía de Investigación se constituirá de forma temporal o permanente para conocer cada caso que le deba ser sometido y aplicará los procedimientos y las reglas previstas en la presente Ley. la integración, organización y funcionamiento del Consejo Disciplinario de Policía de Investigación del Cuerpo de Investigaciones Científicas, Penales y Criminalísticas se rige por lo establecido en la presente Ley, sus reglamentos y resoluciones.

`[ ] Es correcto`  `[ ] Es un error`

### ley-del-estatuto-de-la-funcion-de-la-policia-de-investigacion · art. 89

**Error detectado:** …el registro correspondiente a la desincorporación del listad ⟦o. y⟧  credenciales funcionariales, y a los fines de dar cumplimie…

**Texto completo:**

> La destitución acordada, una vez firme la decisión correspondiente, será notificada al Ministerio del Poder Popular con competencia en materia de seguridad ciudadana a fin de efectuar el registro correspondiente a la desincorporación del listado. y credenciales funcionariales, y a los fines de dar cumplimiento al Decreto con Rango, Valor y Fuerza de Ley Orgánica del Servicio de Policía de Investigación, el Cuerpo de Investigaciones Científicas, Penales y Criminalísticas y el Instituto Nacional de Mediana y Ciencias Forenses.
> 
> Si la destitución procediere por la comisión de un delito, la Directora o Director del Cuerpo de Investigaciones Científicas, Penales y Criminalísticas notificará al Ministerio Público a los fines de iniciar la averiguación penal a que hubiere lugar. En caso que el Ministerio Público hubiere iniciado de oficio una averiguación por la comisión de un delito, la Directora o Director del cuerpo de policía correspondiente procederá a suspender del ejercicio de sus funciones al funcionaria o funcionario policial o experta y experto en materia de investigación penal cuando su acusación haya sido admitida por el Tribunal respectivo.

`[ ] Es correcto`  `[ ] Es un error`

### ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes · art. 326

**Error detectado:** …ar la medida o decisión que corresponda en caso de abstenció ⟦n. e⟧ n estos casos, el juez o jueza podrá ordenar su ejecución al…

**Texto completo:**

> Sentencia en asuntos provenientes de los consejos municipales de derechosde niños, niñas y adolescentes y consejos de protección de niños, niñas y adolescentes.
> 
> En la sentencia de los procedimientos contencioso administrativos especiales referidos a los asuntos previstos en el Parágrafo Tercero del artículo 177 de esta Ley, el juez o jueza podrá confirmar, revocar o modificar la medida impuesta por el consejo municipal de derechos de niños, niñas y adolescentes o el consejo de protección de niños, niñas y adolescentes, así como dictar la medida o decisión que corresponda en caso de abstención. en estos casos, el juez o jueza podrá ordenar su ejecución al consejo municipal de derechos de niños, niñas y adolescentes o al consejo de protección de niños, niñas y adolescentes, según el caso.

`[ ] Es correcto`  `[ ] Es un error`

### ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes · art. 387

**Error detectado:** …ueza no fijará el régimen de convivencia familiar provisiona ⟦l.

e⟧ l régimen de convivencia familiar supervisado será estableci…

**Texto completo:**

> El régimen de convivencia familiar debe ser convenido de mutuo acuerdo entre el padre y la madre, oyendo al hijo o hija. De no lograrse dicho acuerdo cualquiera de ellos o el hijo o hija adolescentes podrá solicitar al juez o jueza que fije el régimen de convivencia familiar, quien decidirá atendiendo al interés superior de los hijos e hijas. La decisión podrá ser revisada a solicitud de la parte, cada vez que el bienestar del niño, niña o adolescentes lo justifique.
> 
> Al admitir la solicitud, el juez o jueza apreciando la gravedad y urgencia de la situación podrá fijar el régimen de convivencia familiar provisional que juzgue conveniente para garantizar este derecho y tomar todas las medidas necesarias para su cumplimiento inmediato. En la audiencia preliminar el juez o jueza deberá fijar un régimen de convivencia familiar provisional, salvo que existan fundados indicios de amenazas o violaciones, en contra del derecho a la vida, la salud o la integridad del niño, niña o adolescente, caso en el cual se fijará un régimen de convivencia familiar provisional supervisado. Excepcionalmente, cuando estas amenazas o violaciones sean graves y existan pruebas suficientes en el procedimiento, el juez o jueza no fijará el régimen de convivencia familiar provisional.
> 
> el régimen de convivencia familiar supervisado será establecido fuera de la sede del tribunal de protección de niños, niñas y adolescentes.

`[ ] Es correcto`  `[ ] Es un error`

### ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes · art. 397-C

**Error detectado:** …en el registro que a tal efecto lleve la autoridad competent ⟦e. e⟧ l tribunal de protección de niños, niñas y adolescentes debe…

**Texto completo:**

> De no localizarse a los progenitores o, habiéndoselos localizado sin que sea posible la integración o reintegración familiar, cumplido el lapso de treinta días continuos previsto en el artículo 127 de esta Ley, el respectivo consejo de protección de niños, niñas y adolescentes, remitirá el expediente del procedimiento administrativo al tribunal de protección de niños, niñas y adolescentes, a fin de que el juez o jueza de mediación y sustanciación proceda a dictar lacorrespondiente medida provisional de colocación en otra familia sustituta o en otra entidad de atención, debidamente inscritas en el registro que a tal efecto lleve la autoridad competente. el tribunal de protección de niños, niñas y adolescentes deberá entregar copia certificada del expediente al consejo de protección de niños, niñas y adolescentes.

`[ ] Es correcto`  `[ ] Es un error`

### ley-organica-para-la-proteccion-de-ninos-ninas-y-adolescentes · art. 401-A

**Error detectado:** …y a los consejos de protección de niños, niñas y adolescente ⟦s. e⟧ l registro de elegibles se debe actualizar cada tres meses.

**Texto completo:**

> Para que a una persona o pareja pueda concedérsele una colocación familiar por un tribunal de protección de niños, niñas y adolescentes, debe inscribirse en un programa de colocación familiar, a fin de ser previamente evaluada bio-psico-social y legalmente, para determinar su idoneidad. Una vez determinada tal idoneidad, la persona debe ser capacitada por el mencionado programa, mediante cursos de formación y orientación para familias sustitutas en modalidad de colocación familiar. Concluida la capacitación, se le incorporará al registro de elegibles en materia de colocación familiar. Copia de este registro debe remitirse al tribunal de protección de niños, niñas y adolescentes, a los consejos municipales de derechos de niños, niñas y adolescentes y a los consejos de protección de niños, niñas y adolescentes. el registro de elegibles se debe actualizar cada tres meses.

`[ ] Es correcto`  `[ ] Es un error`

### ley-penal-del-ambiente · art. 19

**Error detectado:** …s, si el delito mereciere pena de prisión de más de tres año ⟦s.

b⟧ .- A los tres años, si el delito mereciere pena de prisión d…

**Texto completo:**

> Las acciones penales y civiles derivadas de la presente Ley, prescribirán así:
> 
> 1.- Las penales:
> 
> a.- A los cinco años, si el delito mereciere pena de prisión de más de tres años.
> 
> b.- A los tres años, si el delito mereciere pena de prisión de tres años o menos, o arresto de más de seis meses.
> 
> c.- Al año, si el hecho punible sólo acarreare arresto por tiempo de uno a seis meses.
> 
> 2.- Las civiles:

`[ ] Es correcto`  `[ ] Es un error`

### ley-penal-del-ambiente · art. 29

**Error detectado:** …icios ambientales a la comunidad, de acuerdo a su formación  ⟦y. h⟧ abilidades y la asistencia obligatoria a cursos, talleres o …

**Texto completo:**

> Para el otorgamiento de los beneficios previstos en el Código Orgánico Procesal Penal u otras leyes de similar naturaleza, el juez o jueza, además de los requisitos allí establecidos, deberá imponer como condición la realización de las medidas ambientales necesarias para interrumpir el daño, hacer cesar sus consecuencias lesivas y restaurar o reordenar el ambiente; y si el delito fuere de peligro y no se hubiere producido un daño, la ejecución de servicios ambientales a la comunidad, de acuerdo a su formación y. habilidades y la asistencia obligatoria a cursos, talleres o clases de educación y gestión ambiental.

`[ ] Es correcto`  `[ ] Es un error`

### ley-sobre-el-hurto-y-robo-de-vehiculos-automotores · art. 8

**Error detectado:** …motores, de su serial de carrocería o de motor, para asegura ⟦r. l⟧ a impunidad de los autores de delitos de hurto o robo, o de …

**Texto completo:**

> Quienes sustraigan, cambien o alteren ilícitamente las placas de vehículos automotores, de su serial de carrocería o de motor, para asegurar. la impunidad de los autores de delitos de hurto o robo, o de sus cómplices, o para obtener un provecho económico, para sí o para un tercero, serán sancionados con pena de dos a cuatro años de prisión.

`[ ] Es correcto`  `[ ] Es un error`

### reglamento-de-la-ley-de-abogados · art. 45

**Error detectado:** …legio, el día previamente determinado, comenzando a las 8 a. ⟦m. y⟧  terminando a las 8 p.m.

**Texto completo:**

> Las votaciones se realizarán en la sede del Colegio, el día previamente determinado, comenzando a las 8 a.m. y terminando a las 8 p.m.

`[ ] Es correcto`  `[ ] Es un error`

