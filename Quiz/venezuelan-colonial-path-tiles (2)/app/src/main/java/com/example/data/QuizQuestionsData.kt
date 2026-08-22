package com.example.data

import com.example.model.QuizQuestion

val RAW_QUIZ_QUESTIONS = listOf(
    QuizQuestion(
        id = "Q_1",
        nivel = 1,
        delitoBase = "Flagrancia y Procedimiento Abreviado",
        contextoNarrativo = "Pedro, de 25 años, es sorprendido por funcionarios policiales sustrayendo un teléfono celular del bolso de María en una estación del metro. Al ser detenido, Pedro opone resistencia física leve pero es reducido. El Ministerio Público solicita la aplicación del procedimiento abreviado por flagrancia. La defensa alega que no puede aplicarse dicho procedimiento porque no hubo orden judicial previa de allanamiento. ¿Es procedente la solicitud fiscal?",
        opciones = listOf(
            "No, porque toda detención requiere orden judicial previa según el artículo 44 de la CRBV.",
            "Sí, porque el artículo 234 del COPP permite la aprehensión en flagrancia sin orden judicial cuando el delito se comete en el momento.",
            "No, porque el hurto de celular es un delito de acción privada que requiere instancia de parte agraviada.",
            "Sí, pero solo si la víctima otorga su consentimiento expreso para la persecución penal."
        ),
        respuestaCorrecta = 1,
        dificultad = "Básica",
        fundamentacion = "El artículo 44.1 de la CRBV establece como excepción a la orden judicial de detención el caso de flagrancia. El artículo 234 del COPP define la flagrancia como el delito que se está cometiendo en el momento o acaba de cometerse, y el autor es sorprendido en el acto. Al ser Pedro sorprendido sustrayendo el teléfono, la aprehensión es legal sin orden previa. El hurto de celular constituye delito de acción pública (hurto simple, Art. 451 CP).",
        pista = "Revise la excepción constitucional a la orden judicial previa en flagrancia según el Art. 44 CRBV y 234 COPP."
    ),
    QuizQuestion(
        id = "Q_2",
        nivel = 2,
        delitoBase = "Garantía Constitucional de Presentación Judicial",
        contextoNarrativo = "Ana, de 30 años, es detenida por funcionarios del CICPC señalada de haber cometido un homicidio hace 48 horas. Los funcionarios la mantienen en la sede policial por 72 horas antes de presentarla ante el Juez de Control, argumentando que necesitaban culminar las entrevistas a testigos. ¿Se ha vulnerado alguna garantía constitucional?",
        opciones = listOf(
            "No, porque el plazo de 72 horas está dentro del lapso razonable para investigaciones complejas.",
            "Sí, se vulneró el artículo 44.1 de la CRBV, que establece un plazo máximo de 48 horas para poner al detenido a disposición judicial.",
            "No, porque en delitos de homicidio el plazo se extiende automáticamente a 96 horas según el COPP.",
            "Sí, pero solo si Ana no había designado abogado defensor antes de las 48 horas."
        ),
        respuestaCorrecta = 1,
        dificultad = "Básica",
        fundamentacion = "El artículo 44.1 de la Constitución de la República Bolivariana de Venezuela establece que la persona detenida debe ser llevada ante la autoridad judicial en un plazo no mayor de 48 horas a partir de la detención. El COPP (Art. 236) reitera este plazo infranqueable.",
        pista = "La Constitución venezolana estipula un límite estricto de 48 horas para la presentación del aprehendido."
    ),
    QuizQuestion(
        id = "Q_3",
        nivel = 3,
        delitoBase = "Acción Pública vs. Acción Privada y Perdón",
        contextoNarrativo = "Luis, de 40 años, es acusado por el delito de lesiones personales graves (Art. 415 CP). En la audiencia preliminar, su defensa solicita el sobreseimiento alegando que la víctima, su vecino, lo perdonó por escrito y no desea continuar con el proceso. El Ministerio Público se opone. ¿Debe el Juez de Control decretar el sobreseimiento?",
        opciones = listOf(
            "Sí, porque el perdón del ofendido extingue la acción penal en todos los delitos contra las personas.",
            "No, porque las lesiones personales graves son un delito de acción pública y el perdón del ofendido solo extingue la acción en delitos de instancia privada.",
            "Sí, siempre que el perdón sea otorgado ante el Juez y homologado por este.",
            "No, porque el perdón del ofendido solo aplica cuando el acusado es menor de edad."
        ),
        respuestaCorrecta = 1,
        dificultad = "Media",
        fundamentacion = "El artículo 25 del COPP enumera taxativamente los delitos de acción privada. Las lesiones graves (Art. 415 CP) son un delito de acción pública perseguible de oficio por el Ministerio Público, por lo que el perdón de la víctima no extingue la acción penal.",
        pista = "Distinga la naturaleza de los delitos de acción pública perseguibles de oficio frente a los delitos a instancia privada."
    ),
    QuizQuestion(
        id = "Q_4",
        nivel = 4,
        delitoBase = "Suspensión Condicional de la Ejecución de la Pena",
        contextoNarrativo = "Carlos, de 22 años, es condenado por primera vez por el delito de hurto simple (Art. 451 CP) a la pena de 2 años de prisión. El Juez de Ejecución le otorga la Suspensión Condicional de la Ejecución de la Pena. Como condición, le impone presentarse cada 15 días ante la Unidad Técnica de Supervisión y no cometer nuevo delito. ¿Cuál es la base legal principal de este beneficio?",
        opciones = listOf(
            "Artículo 44 de la CRBV sobre la libertad personal.",
            "Artículo 493 del COPP, que regula las fórmulas alternativas de cumplimiento de pena.",
            "Artículo 60 del Código Penal sobre la condena condicional.",
            "Artículo 234 del COPP sobre la flagrancia."
        ),
        respuestaCorrecta = 2,
        dificultad = "Básica",
        fundamentacion = "La Suspensión Condicional de la Ejecución de la Pena (condena condicional) está prevista en el artículo 60 del Código Penal venezolano, aplicable en primera condena con penas no mayores a los límites de ley.",
        pista = "La figura sustantiva de la condena condicional está consagrada en el Código Penal."
    ),
    QuizQuestion(
        id = "Q_5",
        nivel = 5,
        delitoBase = "Porte Ilícito de Armas de Fuego",
        contextoNarrativo = "Miguel, de 28 años, es aprehendido por funcionarios de la GNB en un punto de control al hallarle una pistola 9mm sin documentación. Alega que se la dejó un amigo y que no sabía que requería permiso. ¿Qué delito se configura prima facie según la ley especial?",
        opciones = listOf(
            "Porte Ilícito de Arma de Fuego, previsto en el artículo 112 de la Ley para el Desarme y Control de Armas y Municiones.",
            "Hurto de arma de fuego, previsto en el Código Penal.",
            "Tenencia de arma de guerra, tipificado en la Ley de Desarme.",
            "No se configura delito porque no hubo intención de cometer un hecho punible con el arma."
        ),
        respuestaCorrecta = 0,
        dificultad = "Media",
        fundamentacion = "La Ley para el Desarme y Control de Armas y Municiones (2013), en su artículo 112, sanciona el porte ilícito de arma de fuego con prescindencia del ánimo de cometer otro hecho punible.",
        pista = "Considere la ley especial para el desarme vigente desde el año 2013."
    ),
    QuizQuestion(
        id = "Q_6",
        nivel = 6,
        delitoBase = "Posesión Ilícita vs. Tráfico de Drogas",
        contextoNarrativo = "Durante un allanamiento autorizado, funcionarios hallan en la habitación de José 50 gramos de marihuana. Alega que es para su consumo personal. Según la LOD y la jurisprudencia, ¿qué determina principalmente si la conducta es consumo o tráfico?",
        opciones = listOf(
            "La confesión del imputado sobre el destino de la droga.",
            "La cantidad de droga incautada, que al exceder los límites legales para consumo personal, permite inferir el ánimo de tráfico.",
            "El hecho de que la droga estuviera oculta en la habitación.",
            "La presentación de testigos que declaren que José es consumidor habitual."
        ),
        respuestaCorrecta = 1,
        dificultad = "Alta",
        fundamentacion = "La Ley Orgánica de Drogas (LOD) establece parámetros objetivos de cantidad (Art. 153 vs 149). Cantidades que exceden significativamente la dosis presunta de consumo invierten la presunción hacia el ánimo de distribución.",
        pista = "El criterio objetivo cuantitativo es determinante en la inferencia del tipo penal."
    ),
    QuizQuestion(
        id = "Q_7",
        nivel = 7,
        delitoBase = "Fases del Proceso Penal Acusatorio",
        contextoNarrativo = "Laura es denunciada por su vecina por presuntas lesiones leves tras una disputa de estacionamiento. La Fiscalía inicia la investigación. ¿En cuál de las fases del proceso penal venezolano se encuentra este caso?",
        opciones = listOf(
            "Fase de Juicio Oral y Público.",
            "Fase Intermedia.",
            "Fase de Ejecución.",
            "Fase Preparatoria."
        ),
        respuestaCorrecta = 3,
        dificultad = "Básica",
        fundamentacion = "El proceso penal venezolano en el COPP se divide en Fase Preparatoria (investigación fiscal), Intermedia (audiencia preliminar), Juicio Oral y Público, y Ejecución.",
        pista = "Es la fase inicial de acopio de elementos de convicción dirigida por el Ministerio Público."
    ),
    QuizQuestion(
        id = "Q_8",
        nivel = 8,
        delitoBase = "Principio de Afirmación de la Libertad",
        contextoNarrativo = "Daniel es imputado por robo genérico. En la audiencia de presentación, el Juez de Control decreta Medida Cautelar Sustitutiva de presentación periódica cada 15 días. ¿Qué principio rige esta decisión en contraposición a la privación preventiva?",
        opciones = listOf(
            "Principio de Legalidad Material.",
            "Principio de Afirmación de la Libertad y de Excepcionalidad de la Privación de Libertad.",
            "Principio de Inmediación Procesal.",
            "Principio de Proporcionalidad de la Pena."
        ),
        respuestaCorrecta = 1,
        dificultad = "Media",
        fundamentacion = "El artículo 9 del COPP consagra la afirmación de la libertad como principio rector, estableciendo que la privación judicial preventiva durante el proceso tiene carácter estrictamente excepcional (Art. 229 COPP).",
        pista = "Principio rector del artículo 9 del Código Orgánico Procesal Penal."
    ),
    QuizQuestion(
        id = "Q_9",
        nivel = 9,
        delitoBase = "Peculado Doloso",
        contextoNarrativo = "Javier, funcionario de una alcaldía, es acusado de apropiarse de materiales de construcción municipales para su casa particular. Según la legislación penal venezolana, ¿qué bien jurídico se lesiona principalmente?",
        opciones = listOf(
            "La Propiedad Privada.",
            "La Fe Pública.",
            "La Administración Pública y el Patrimonio Público.",
            "La Libertad Individual."
        ),
        respuestaCorrecta = 2,
        dificultad = "Media",
        fundamentacion = "El peculado (Art. 52 de la Ley Contra la Corrupción) tutela la regularidad, transparencia y probidad de la Administración Pública, así como el patrimonio económico estatal.",
        pista = "El funcionario público vulnera los deberes inherentes al patrimonio estatal y la probidad administrativa."
    ),
    QuizQuestion(
        id = "Q_10",
        nivel = 10,
        delitoBase = "Régimen del Consumidor de Drogas",
        contextoNarrativo = "Marcos, de 18 años, es detenido con 2 gramos de cocaína para su uso personal exclusivo sin antecedentes. Según la Ley Orgánica de Drogas, ¿cómo debe proceder la autoridad judicial competente?",
        opciones = listOf(
            "Decretar la Privación Judicial Preventiva de Libertad por tráfico de drogas.",
            "Sobreseer la causa por tratarse de una cantidad ínfima.",
            "Aplicar el procedimiento especial para consumidores con medidas de seguridad y tratamiento de rehabilitación.",
            "Imponer una pena de multa exclusivamente."
        ),
        respuestaCorrecta = 2,
        dificultad = "Media",
        fundamentacion = "El artículo 128 de la LOD prevé para consumidores medidas de seguridad, tratamiento y desintoxicación en lugar de penas privativas de libertad tradicionales.",
        pista = "El marco legal trata al consumidor bajo un enfoque de salud pública y medidas de seguridad."
    ),
    QuizQuestion(
        id = "Q_11",
        nivel = 11,
        delitoBase = "Competencia en Violencia de Género",
        contextoNarrativo = "Ricardo es acusado de violencia psicológica contra su esposa (Art. 39 Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia). ¿Cuál es el tribunal competente para conocer de este caso?",
        opciones = listOf(
            "Un Tribunal de Primera Instancia en Funciones de Control Ordinario (Penal Ordinario).",
            "Un Tribunal de Violencia contra la Mujer en Funciones de Control, Audiencias y Medidas.",
            "Un Tribunal de Protección de Niños, Niñas y Adolescentes.",
            "Un Juzgado de Municipio en materia Civil."
        ),
        respuestaCorrecta = 1,
        dificultad = "Básica",
        fundamentacion = "El artículo 13 de la Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia establece los Tribunales Especiales con competencia en Delitos de Violencia contra la Mujer.",
        pista = "Existe una jurisdicción penal especial creada por ley orgánica para esta materia."
    ),
    QuizQuestion(
        id = "Q_12",
        nivel = 12,
        delitoBase = "Confesión Espontánea como Atenuante",
        contextoNarrativo = "Andrés se presenta voluntariamente ante el CICPC y confiesa haber participado en un robo hace un mes aportando detalles antes de ser investigado. ¿Qué efecto jurídico-procesal tiene esta conducta?",
        opciones = listOf(
            "Extingue la acción penal automáticamente.",
            "Puede ser considerada como una circunstancia atenuante genérica en la determinación de la pena (Art. 74 ordinal 4° CP).",
            "Obliga al Juez a otorgar la libertad plena sin restricciones.",
            "Convierte el delito en falta."
        ),
        respuestaCorrecta = 1,
        dificultad = "Media",
        fundamentacion = "El artículo 74, ordinal 4° del Código Penal establece como circunstancia atenuante el haber confesado el hecho antes de tener conocimiento de la apertura del procedimiento judicial.",
        pista = "La confesión sincera previa es una circunstancia atenuante genérica en el Código Penal."
    ),
    QuizQuestion(
        id = "Q_13",
        nivel = 13,
        delitoBase = "Prohibición de Justicia por Mano Propia",
        contextoNarrativo = "Vecinos sorprenden a Erick forzando una cerradura, lo atan a un poste y lo golpean antes de llamar a la policía. ¿Qué principio constitucional vulneraron los vecinos?",
        opciones = listOf(
            "El Principio de Legalidad de las Penas.",
            "El Principio de Presunción de Inocencia y el Derecho a la Integridad Personal (Art. 46 y 49 CRBV).",
            "El Principio de Confidencialidad del Proceso.",
            "El Principio de la Doble Instancia."
        ),
        respuestaCorrecta = 1,
        dificultad = "Básica",
        fundamentacion = "Los artículos 46 y 49 de la CRBV garantizan la integridad física y el debido proceso. La justicia por mano propia está proscrita en el ordenamiento constitucional.",
        pista = "La Carta Magna prohíbe todo trato degradante y salvaguarda la integridad y debido proceso."
    ),
    QuizQuestion(
        id = "Q_14",
        nivel = 14,
        delitoBase = "Principio de Irretroactividad y Ley Más Favorable",
        contextoNarrativo = "Entra en vigencia una reforma del Código Penal que aumenta la pena de la estafa de 1-5 años a 4-8 años. Roberto cometió la estafa antes de la reforma pero es sentenciado después. ¿Qué pena debe aplicarse?",
        opciones = listOf(
            "La pena de 4 a 8 años, por ser la ley vigente al momento de la sentencia.",
            "La pena de 1 a 5 años, en virtud del principio de irretroactividad de la ley penal más gravosa (Art. 24 CRBV y Art. 2 CP).",
            "El juez puede aplicar la pena que considere más justa entre ambas.",
            "Se debe aplicar un término medio entre ambas penas."
        ),
        respuestaCorrecta = 1,
        dificultad = "Básica",
        fundamentacion = "El Art. 24 de la CRBV y el Art. 2 del Código Penal consagran la irretroactividad de la ley penal perjudicial y la aplicación ultraactiva de la ley más benigna.",
        pista = "Principio de favorabilidad procesal y sustantiva consagrado en el Art. 24 CRBV."
    ),
    QuizQuestion(
        id = "Q_17",
        nivel = 17,
        delitoBase = "Límites de la Legítima Defensa",
        contextoNarrativo = "Fernando es sorprendido intentando sustraer una bicicleta. El dueño le dispara por la espalda con una escopeta cuando Fernando ya se encontraba huyendo, causándole la muerte. ¿Procede la legítima defensa?",
        opciones = listOf(
            "Sí, porque estaba defendiendo su propiedad de un robo.",
            "No, porque no hubo agresión ilegítima actual o inminente, ya que el sujeto se encontraba en fuga y no representaba un peligro a la vida.",
            "Sí, pero solo como atenuante.",
            "No, porque el dueño no era funcionario policial."
        ),
        respuestaCorrecta = 1,
        dificultad = "Media",
        fundamentacion = "El Art. 65 del Código Penal exige agresión actual o inminente y necesidad racional del medio. Al cesar el ataque y emprender la fuga, disparar por la espalda constituye un exceso no justificado.",
        pista = "La agresión debe ser actual o inminente al momento de repelerla."
    ),
    QuizQuestion(
        id = "Q_26",
        nivel = 26,
        delitoBase = "Requisitos de la Privación Judicial Preventiva",
        contextoNarrativo = "¿Qué extremos concurrentes debe verificar el Juez de Control para decretar la privación preventiva de libertad según el artículo 236 del COPP?",
        opciones = listOf(
            "Un hecho punible con pena privativa de libertad, fundados elementos de convicción de autoría/participación y presunción razonable de peligro de fuga o de obstaculización.",
            "La confesión del imputado sobre los hechos.",
            "La opinión de la víctima sobre la medida a imponer.",
            "El tiempo transcurrido desde la comisión del delito."
        ),
        respuestaCorrecta = 0,
        dificultad = "Básica",
        fundamentacion = "El Art. 236 del COPP exige concurrentemente: Delito grave con pena corporal, fundados elementos de convicción y peligro procesal (fuga u obstaculización probatoria).",
        pista = "Son los 3 numerales concurrentes del artículo 236 del COPP."
    ),
    QuizQuestion(
        id = "Q_28",
        nivel = 28,
        delitoBase = "Derecho a la No Autoincriminación",
        contextoNarrativo = "Durante un juicio, el acusado José decide no declarar. El fiscal solicita al juez que valore ese silencio como indicio de culpabilidad. ¿Es procedente la solicitud fiscal?",
        opciones = listOf(
            "Sí, porque todo acusado tiene el deber de declarar para esclarecer los hechos.",
            "No, porque el derecho a no declarar contra sí mismo es una garantía constitucional y su ejercicio no puede ser valorado en su contra (Art. 49.5 CRBV y 132 COPP).",
            "Sí, siempre que existan otros indicios concordantes.",
            "No, pero solo si el acusado lo solicita formalmente al inicio del juicio."
        ),
        respuestaCorrecta = 1,
        dificultad = "Básica",
        fundamentacion = "El Art. 49.5 de la CRBV y el Art. 132 del COPP prohíben expresamente extraer inferencias perjudiciales del silencio o abstención de declarar del procesado.",
        pista = "Garantía constitucional del nemo tenetur se ipsum accusare."
    ),
    QuizQuestion(
        id = "Q_40",
        nivel = 40,
        delitoBase = "Procedimiento Especial por Admisión de Hechos",
        contextoNarrativo = "Un acusado de estafa manifiesta su voluntad de admitir los hechos para optar a la rebaja de pena. ¿En qué momentos procesales puede hacerlo según el COPP?",
        opciones = listOf(
            "Solo en la fase preparatoria.",
            "Únicamente en la audiencia preliminar.",
            "En la audiencia preliminar o, una vez abierto el juicio, antes de la recepción de las pruebas (Art. 375 COPP).",
            "En cualquier momento antes de la sentencia definitiva."
        ),
        respuestaCorrecta = 2,
        dificultad = "Media",
        fundamentacion = "El Art. 375 del COPP permite admitir hechos en la audiencia preliminar (rebaja de hasta la mitad) o antes del debate probatorio en juicio (rebaja de un tercio).",
        pista = "Revise las dos oportunidades temporales fijadas en el artículo 375 del COPP."
    ),
    QuizQuestion(
        id = "Q_52",
        nivel = 52,
        delitoBase = "Doctrina Constitucional Vinculante",
        contextoNarrativo = "La Sala Constitucional del TSJ dicta una sentencia interpretativa con carácter vinculante. ¿Cuál es su alcance para los jueces de instancia?",
        opciones = listOf(
            "No, porque los jueces son autónomos en la interpretación de la ley.",
            "Sí, es vinculante para todos los tribunales de la República según el artículo 335 de la CRBV.",
            "Solo es vinculante si la publica el Ministerio Público.",
            "Es una simple recomendación académica."
        ),
        respuestaCorrecta = 1,
        dificultad = "Media",
        fundamentacion = "El Art. 335 de la CRBV confiere a la Sala Constitucional la máxima potestad interpretativa, siendo sus fallos sobre normas constitucionales vinculantes erga omnes.",
        pista = "Revise el poder normativo del Art. 335 de la Constitución."
    ),
    QuizQuestion(
        id = "Q_84",
        nivel = 84,
        delitoBase = "Principio In Dubio Pro Reo",
        contextoNarrativo = "¿En qué consiste el principio procesal penal 'In Dubio Pro Reo' consagrado en el sistema venezolano?",
        opciones = listOf(
            "La duda favorece a la víctima en el restablecimiento patrimonial.",
            "En caso de duda razonable sobre la culpabilidad del acusado tras el debate, el juez debe dictar sentencia absolutoria (Art. 49.2 CRBV).",
            "La duda se resuelve ordenando una nueva investigación fiscal.",
            "La duda permite al juez condenar aplicando una atenuante genérica."
        ),
        respuestaCorrecta = 1,
        dificultad = "Básica",
        fundamentacion = "Emanación directa del estado de presunción de inocencia (Art. 49.2 CRBV). La certeza positiva es requisito inexcusable para la condena; la duda obliga a la absolución.",
        pista = "Axioma procesal que impone la absolución frente a la duda probatoria insuperable."
    ),
    QuizQuestion(
        id = "Q_99",
        nivel = 99,
        delitoBase = "Garantía de Imputación Formal Previa",
        contextoNarrativo = "La defensa solicita la nulidad de la acusación fiscal porque no se realizó el acto de imputación formal previamente. ¿Es obligatorio este acto?",
        opciones = listOf(
            "No, basta con la presentación de la acusación.",
            "Sí, el acto de imputación formal en sede fiscal es un requisito de procedibilidad indispensable fijado con carácter vinculante por el TSJ para garantizar el derecho a la defensa.",
            "Solo es necesario en delitos flagrantes.",
            "Depende del mero criterio del fiscal actuante."
        ),
        respuestaCorrecta = 1,
        dificultad = "Alta",
        fundamentacion = "La jurisprudencia vinculante de la Sala Constitucional del TSJ (Sent. 537/2017) declara que el acto formal de imputación es garantía constitucional irrenunciable para ejercer la defensa previa a la acusación.",
        pista = "Doctrina vinculante de la Sala Constitucional sobre el debido proceso en fase de investigación."
    ),
    QuizQuestion(
        id = "Q_100",
        nivel = 100,
        delitoBase = "Suspensión de Pena en Sentencia",
        contextoNarrativo = "Una persona es condenada por primera vez a 3 años de prisión. El Juez considera que no requiere tratamiento carcelario. ¿Qué fórmula puede aplicar directamente en la sentencia?",
        opciones = listOf(
            "La libertad condicional anticipada.",
            "La Suspensión Condicional de la Ejecución de la Pena, conforme al artículo 60 del Código Penal.",
            "El Régimen Abierto penitenciario.",
            "El indulto judicial ordinario."
        ),
        respuestaCorrecta = 1,
        dificultad = "Media",
        fundamentacion = "El artículo 60 del Código Penal faculta al tribunal sentenciador a suspender la ejecución corporal en condenas primarias no mayores a 5 años.",
        pista = "Facultad directa conferida al sentenciador en el Art. 60 del Código Penal."
    )
)

fun getQuestionForLevel(level: Int): QuizQuestion {
    val exact = RAW_QUIZ_QUESTIONS.find { it.nivel == level }
    if (exact != null) return exact

    // Generador dinámico inteligente para mapear sin límites hasta 3000 niveles
    val baseIndex = (level - 1) % RAW_QUIZ_QUESTIONS.size
    val base = RAW_QUIZ_QUESTIONS[baseIndex]
    return QuizQuestion(
        id = "Q_$level",
        nivel = level,
        delitoBase = base.delitoBase,
        contextoNarrativo = "Caso Judicial No. 2026-$level (Nivel $level): ${base.contextoNarrativo}",
        opciones = base.opciones,
        respuestaCorrecta = base.respuestaCorrecta,
        dificultad = when {
            level > 2400 -> "Sala de Casación Penal (TSJ)"
            level > 1800 -> "Corte de Apelaciones"
            level > 900 -> "Primera Instancia"
            else -> "Tribunal de Municipio"
        },
        fundamentacion = base.fundamentacion,
        pista = base.pista
    )
}
