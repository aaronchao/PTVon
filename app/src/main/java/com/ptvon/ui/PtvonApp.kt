package com.ptvon.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.ptvon.ui.dashboard.DashboardScreen
import com.ptvon.ui.onboarding.OnboardingScreen
import com.ptvon.ui.onboarding.OnboardingViewModel
import com.ptvon.ui.search.SearchScreen
import com.ptvon.ui.theme.PtvonTheme
import com.ptvon.ui.theme.ThemeMode
import com.ptvon.ui.theme.ThemeViewModel

object Routes {
    const val ONBOARDING = "onboarding"
    const val DASHBOARD = "dashboard"
    const val SEARCH = "search"
}

@Composable
fun PtvonApp(
    themeViewModel: ThemeViewModel = hiltViewModel(),
    onboardingViewModel: OnboardingViewModel = hiltViewModel(),
) {
    val themeMode by themeViewModel.themeMode.collectAsStateWithLifecycle()
    val isDark = when (themeMode) {
        ThemeMode.SYSTEM -> isSystemInDarkTheme()
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
    }
    val hasOnboarded by onboardingViewModel.hasOnboarded.collectAsStateWithLifecycle()

    PtvonTheme(themeMode = themeMode) {
        Surface(modifier = Modifier.fillMaxSize()) {
            // Wait until the onboarding flag is known to avoid flashing the wrong screen.
            val onboarded = hasOnboarded ?: return@Surface
            val navController = rememberNavController()
            NavHost(
                navController = navController,
                startDestination = if (onboarded) Routes.DASHBOARD else Routes.ONBOARDING,
            ) {
                composable(Routes.ONBOARDING) {
                    OnboardingScreen(
                        onGetStarted = {
                            onboardingViewModel.complete()
                            navController.navigate(Routes.SEARCH) {
                                popUpTo(Routes.ONBOARDING) { inclusive = true }
                            }
                        },
                        onSkip = {
                            onboardingViewModel.complete()
                            navController.navigate(Routes.DASHBOARD) {
                                popUpTo(Routes.ONBOARDING) { inclusive = true }
                            }
                        },
                    )
                }
                composable(Routes.DASHBOARD) {
                    DashboardScreen(
                        onAddStops = { navController.navigate(Routes.SEARCH) },
                        isDark = isDark,
                        onToggleTheme = { themeViewModel.toggle(isDark) },
                    )
                }
                composable(Routes.SEARCH) {
                    SearchScreen(
                        onBack = {
                            if (!navController.popBackStack(Routes.DASHBOARD, inclusive = false)) {
                                navController.navigate(Routes.DASHBOARD) {
                                    popUpTo(0) { inclusive = true }
                                }
                            }
                        },
                    )
                }
            }
        }
    }
}
