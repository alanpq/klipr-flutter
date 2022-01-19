// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// No Node.js APIs are available in this process unless
// nodeIntegration is set to true in webPreferences.
// Use preload.js to selectively enable features
// needed in the renderer process.

const dom = {
  file: document.getElementById("file") as HTMLInputElement,
  playback: document.getElementById("playback") as HTMLVideoElement,
};

dom.file.addEventListener("change", (e: Event) => {
  console.log(`Playing file '${dom.file.value}'...`)
  dom.playback.src = URL.createObjectURL(dom.file.files[0]);
  dom.playback.play();
})

// window.addEventListener("load", () => {

// });