const controls = {
  play: document.getElementById("play"),
  mute: document.getElementById("mute"),
  volume: document.getElementById("volume") as HTMLInputElement,
  timestamp: document.getElementById("timestamp"),
}

controls.play.onclick = () => {
  if (dom.playback.paused) dom.playback.play();
  else dom.playback.pause();
}

controls.mute.onclick = () => {
  dom.playback.muted = !dom.playback.muted;
}

controls.volume.onchange = (e) => {
  dom.playback.volume = controls.volume.valueAsNumber / 100;
}