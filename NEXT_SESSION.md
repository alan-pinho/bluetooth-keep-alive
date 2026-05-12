# Próxima sessão — ponto de retomada

Última sessão: 2026-05-11. Refator connection-aware completo e mergeado (Phases 1–6 do plano em `~/.claude/plans/o-estado-atual-deste-robust-kay.md`). Builds Debug+Release limpos.

## 🎯 Próxima feature: keep-alive por blip de áudio

**Problema:** alguns devices de áudio (headsets, alto-falantes Bluetooth) não respondem a `IOBluetoothDevice.performSDPQuery`. Para esses, o mecanismo de keep-alive precisa ser tocar uma faixa silenciosa em vez de SDP.

**Design proposto (ainda não implementado):**

- Novo arquivo `Souces/Core/Services/Pinger/AudioBlipStrategy.swift` — mantém um `AVAudioEngine` running com `AVAudioPlayerNode` ligado ao default output. Cada tick agenda um buffer PCM de ~200ms zero-initialized (silêncio). Reusar o buffer entre ticks (sem alocação por tick).
- Refator de `ClassicBluetoothPinger`: o tipo concreto continua, mas internamente delega para uma `KeepAliveStrategy` (protocol) escolhida por device. Implementações: `SDPQueryStrategy` (atual) e `AudioBlipStrategy` (nova).
- **Decisão de UX em aberto** — perguntar ao usuário:
  - Opção A (auto-detect): inspecionar `device.deviceClassMajor == kBluetoothDeviceClassMajorAudio` (0x04) ou checar `serviceClassMajor` para Audio (0x20). Se for áudio → blip; senão → SDP. Sem migration, sem UI nova.
  - Opção B (escolha manual): nova coluna `keepAliveStrategy: String` em `Routines` (migration v3), picker no `DeviceView`. Mais explícito mas precisa mais código.
  - Opção C (auto + override): default auto-detect, mas com override manual no DeviceView para casos em que a detecção erra.
- DeviceView: mostrar "Keep-alive method: Audio blip" + dica "make sure this device is the active audio output" quando a estratégia for áudio.
- Limitação aceita: o blip sai pelo default output do macOS. Se o device não for o output ativo, o silêncio não chega nele. Para o caso de uso real (manter fone "em uso" ativo), isso bate com o cenário do usuário.

**Onde encaixa na arquitetura existente:**
- `ClassicBluetoothPinger` já é a única coisa registrada no `PingerRegistry` para `.classic`. Adicionar a estratégia interna não muda a forma como `RoutineStateStore` ou `TimerRoutineService` o consomem.
- Eventos: `pingOk` deve registrar a estratégia usada via campo `message` (ex: `"audio-blip"`) para diagnóstico em `routine_events`.

## ⏳ Outras pendências menores

- **Stepper interval=0**: `DeviceView` permite 0; só falha no save. Mudar `Stepper(in: 1...3600)` ou desabilitar Save quando `timeInterval == 0`.
- **BLE em rotinas**: `Routines.toRoutineModel` aceita BLE mas `PingerRegistry` só tem classic. Adicionar guard em `DeviceViewModel.saveRoutine` para `.ble(_)` OU implementar `BLEBluetoothPinger`.
- **Histórico de eventos no DeviceView**: `RoutineEventRepository.recent(routineId:limit:)` já existe; falta lista/disclosure mostrando últimas N ocorrências.
- **Ícone reativo no menu bar** (~30min): mudar o ícone quando algum routine estiver dormente ou em snooze.

## 🧪 Validação manual ainda não exercitada

Smoke tests do plano (em hardware real):
- Boot headless via SMAppService: `log stream --predicate 'process == "BluetoothKeepAlive"'` deve mostrar pings sem janela aberta.
- Dormant flow: desligar/religar fone → badge cinza→verde + eventos `disconnected`/`connected` no DB.
- Snooze: pausa 1min via menu → `snoozeSkip` no DB → resume automático.
- Migration em DB existente: rotinas antigas preservadas + tabela `routine_events` criada + `grdb_migrations` populado.
- **Em release assinado**: confirmar que `IOBluetoothDevice.register(forConnectNotifications:)` retorna callbacks com sandbox + `com.apple.security.device.bluetooth=true`.

## 📍 Como retomar

1. Ler `CLAUDE.md` para reentrar na arquitetura nova (RoutineStateStore, pinger registry, snooze, etc).
2. Ler `~/.claude/plans/o-estado-atual-deste-robust-kay.md` para o contexto original do refator.
3. Confirmar com o usuário: Opção A, B ou C para o keep-alive de áudio.
4. Implementar `AudioBlipStrategy` + refator interno do `ClassicBluetoothPinger`.
5. Exercitar a checklist de validação manual antes de fechar.
