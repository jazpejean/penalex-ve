package com.example.state

import android.content.Context
import android.content.SharedPreferences
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.model.getRankForLevel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

enum class Screen {
    DASHBOARD,
    LOBBY,
    RANKING
}

data class RankingJudge(
    val nombre: String,
    val nivel: Int,
    val xp: Int,
    val esUsuario: Boolean = false
)

data class GameUiState(
    val nivelActual: Int = 1,
    val xp: Int = 0,
    val apelaciones: Int = 5,
    val racha: Int = 0,
    val fallosPorNivel: Map<Int, Int> = emptyMap(),
    val currentScreen: Screen = Screen.DASHBOARD,
    val activeQuizLevel: Int? = null // Modal dialog quiz level
)

class GameViewModel(context: Context) : ViewModel() {
    private val prefs: SharedPreferences = context.getSharedPreferences("penalex_prefs", Context.MODE_PRIVATE)

    private val _uiState = MutableStateFlow(
        GameUiState(
            nivelActual = prefs.getInt("nivelActual", 1),
            xp = prefs.getInt("xp", 0),
            apelaciones = prefs.getInt("apelaciones", 5),
            racha = prefs.getInt("racha", 0),
            currentScreen = Screen.DASHBOARD
        )
    )
    val uiState: StateFlow<GameUiState> = _uiState.asStateFlow()

    private val juecesPreestablecidos = listOf(
        RankingJudge("Dra. Carmen E. Zuleta", 2980, 298000),
        RankingJudge("Dr. Maikel Moreno P.", 2750, 275000),
        RankingJudge("Dra. Elsa Janeth Gómez", 2420, 242000),
        RankingJudge("Dr. Alejandro Angulo F.", 1950, 195000),
        RankingJudge("Dr. Luis R. Damiani", 1540, 154000),
        RankingJudge("Abg. Gustavo González", 1100, 110000),
        RankingJudge("Dra. Gladys Gutiérrez", 850, 85000),
        RankingJudge("Abg. Héctor Coronado", 520, 52000),
        RankingJudge("Abg. Yris Peña Espinoza", 280, 28000),
        RankingJudge("Abg. Fernando Vecchionacce", 90, 9000)
    )

    init {
        viewModelScope.launch {
            while (true) {
                delay(30 * 60 * 1000L)
                if (_uiState.value.apelaciones < 5) {
                    _uiState.update { it.copy(apelaciones = it.apelaciones + 1) }
                    saveState()
                }
            }
        }
    }

    private fun saveState() {
        val s = _uiState.value
        prefs.edit()
            .putInt("nivelActual", s.nivelActual)
            .putInt("xp", s.xp)
            .putInt("apelaciones", s.apelaciones)
            .putInt("racha", s.racha)
            .apply()
    }

    fun isLevelLocked(level: Int): Boolean {
        val fallos = _uiState.value.fallosPorNivel[level] ?: 0
        return fallos >= 3
    }

    fun getFailures(level: Int): Int {
        return _uiState.value.fallosPorNivel[level] ?: 0
    }

    fun openQuizModal(level: Int) {
        _uiState.update { it.copy(activeQuizLevel = level) }
    }

    fun closeQuizModal() {
        _uiState.update { it.copy(activeQuizLevel = null) }
    }

    fun responderPregunta(level: Int, esCorrecta: Boolean): Boolean {
        if (esCorrecta) {
            val oldRank = getRankForLevel(_uiState.value.nivelActual)
            val nextLevel = if (level == _uiState.value.nivelActual && _uiState.value.nivelActual < 3000) {
                _uiState.value.nivelActual + 1
            } else {
                _uiState.value.nivelActual
            }

            val updatedFallos = _uiState.value.fallosPorNivel.toMutableMap()
            updatedFallos[level] = 0

            _uiState.update {
                it.copy(
                    nivelActual = nextLevel,
                    xp = it.xp + 100,
                    racha = it.racha + 1,
                    fallosPorNivel = updatedFallos
                )
            }
            saveState()
            val newRank = getRankForLevel(_uiState.value.nivelActual)
            return oldRank != newRank // Devuelve true si subió de rango institucional
        } else {
            val currentFallos = (_uiState.value.fallosPorNivel[level] ?: 0) + 1
            val updatedFallos = _uiState.value.fallosPorNivel.toMutableMap()
            updatedFallos[level] = currentFallos

            _uiState.update {
                it.copy(
                    racha = 0,
                    fallosPorNivel = updatedFallos
                )
            }
            saveState()
            return false
        }
    }

    fun usarApelacion(level: Int): Boolean {
        if (_uiState.value.apelaciones > 0 && isLevelLocked(level)) {
            val updatedFallos = _uiState.value.fallosPorNivel.toMutableMap()
            updatedFallos[level] = 0

            _uiState.update {
                it.copy(
                    apelaciones = it.apelaciones - 1,
                    fallosPorNivel = updatedFallos
                )
            }
            saveState()
            return true
        }
        return false
    }

    fun navigateTo(screen: Screen) {
        _uiState.update { it.copy(currentScreen = screen) }
    }

    fun getRankingList(): List<RankingJudge> {
        val user = RankingJudge(
            nombre = "Tú (Magistrado/a)",
            nivel = _uiState.value.nivelActual,
            xp = _uiState.value.xp,
            esUsuario = true
        )
        val all = juecesPreestablecidos + user
        return all.sortedByDescending { it.xp }
    }
}
