package com.example.model

data class QuizQuestion(
    val id: String,
    val nivel: Int,
    val delitoBase: String,
    val contextoNarrativo: String,
    val opciones: List<String>,
    val respuestaCorrecta: Int, // 0 to 3
    val dificultad: String,
    val fundamentacion: String,
    val pista: String
)
