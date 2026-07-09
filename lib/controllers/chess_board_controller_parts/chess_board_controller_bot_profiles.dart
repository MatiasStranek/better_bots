part of chess_board_controller;

void _controllerSelectBotProfile(
  ChessBoardController controller,
  BotProfile profile,
) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  if (_controllerShouldQueueBotSettings(controller)) {
    controller
      .._pendingBotSettings = null
      .._pendingBotProfile = profile
      .._hasPendingBotProfileChange = true;
    _controllerPersistCurrentState(controller);
    _safeNotify(controller);
    return;
  }

  controller
    .._activeBotProfile = profile
    .._pendingBotProfile = null
    .._hasPendingBotProfileChange = false
    .._pendingBotSettings = null;

  _controllerRefreshTrainingCounterSnapshot(controller);
  _controllerPersistCurrentState(controller);
  _safeNotify(controller);
}

void _controllerDisableBotProfile(ChessBoardController controller) {
  if (controller._isBotThinking || controller.isAnalysisMode) {
    return;
  }

  if (_controllerShouldQueueBotSettings(controller)) {
    controller
      .._pendingBotProfile = null
      .._hasPendingBotProfileChange = true;
    _controllerPersistCurrentState(controller);
    _safeNotify(controller);
    return;
  }

  controller
    .._activeBotProfile = null
    .._pendingBotProfile = null
    .._hasPendingBotProfileChange = false;

  _controllerRefreshTrainingCounterSnapshot(controller);
  _controllerPersistCurrentState(controller);
  _safeNotify(controller);
}

void _controllerApplyPendingBotProfile(ChessBoardController controller) {
  if (!controller._hasPendingBotProfileChange) {
    return;
  }

  controller
    .._activeBotProfile = controller._pendingBotProfile
    .._pendingBotProfile = null
    .._hasPendingBotProfileChange = false;
}
