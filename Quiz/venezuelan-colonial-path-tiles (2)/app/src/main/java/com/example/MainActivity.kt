package com.example

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import com.example.service.SoundAndTtsService
import com.example.state.GameViewModel
import com.example.state.Screen
import com.example.ui.components.QuizModalDialog
import com.example.ui.screens.DashboardScreen
import com.example.ui.screens.LobbyScreen
import com.example.ui.screens.RankingScreen
import com.example.ui.theme.MyApplicationTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MyApplicationTheme {
                val viewModel = remember { GameViewModel(applicationContext) }
                val soundService = remember { SoundAndTtsService(applicationContext) }
                PenalexApp(viewModel, soundService)
            }
        }
    }
}

@Composable
fun PenalexApp(viewModel: GameViewModel, soundService: SoundAndTtsService) {
    val state by viewModel.uiState.collectAsState()

    BackHandler(enabled = state.currentScreen != Screen.DASHBOARD) {
        viewModel.navigateTo(Screen.DASHBOARD)
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0B1020))
    ) {
        when (state.currentScreen) {
            Screen.DASHBOARD -> {
                DashboardScreen(
                    onPlayClick = {
                        viewModel.navigateTo(Screen.LOBBY)
                    },
                    onRankingClick = {
                        viewModel.navigateTo(Screen.RANKING)
                    }
                )
            }
            Screen.LOBBY -> {
                LobbyScreen(
                    state = state,
                    onLevelSelected = { level ->
                        viewModel.openQuizModal(level)
                    },
                    onBackToDashboard = {
                        viewModel.navigateTo(Screen.DASHBOARD)
                    }
                )
            }
            Screen.RANKING -> {
                RankingScreen(
                    rankingList = viewModel.getRankingList(),
                    onBack = {
                        viewModel.navigateTo(Screen.DASHBOARD)
                    }
                )
            }
        }

        // Modal Flotante de Quiz sobre el Lobby
        state.activeQuizLevel?.let { activeLevel ->
            QuizModalDialog(
                level = activeLevel,
                viewModel = viewModel,
                soundService = soundService,
                onDismiss = {
                    viewModel.closeQuizModal()
                }
            )
        }
    }
}
