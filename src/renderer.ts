// This file is required by the index.html file and will
// be executed in the renderer process for that window.
// No Node.js APIs are available in this process unless
// nodeIntegration is set to true in webPreferences.
// Use preload.js to selectively enable features
// needed in the renderer process.

const dom = {
  playback: document.getElementById("playback") as HTMLVideoElement,
  dropZone: document.getElementById("dropZone"),
  videoText: document.querySelector("#video > section") as HTMLVideoElement,
};

const state: {
  file: File
} = {
  file: null,
}


const loadVideo = (file: File) => {
  state.file = file;
  console.log(`Playing file '${file.name}'...`)
  dom.playback.src = URL.createObjectURL(file);
  dom.playback.play();
  dom.videoText.style.visibility = 'hidden';
}

const showDropZone = () => {dom.dropZone.style.visibility = "visible";};
const hideDropZone = () => {dom.dropZone.style.visibility = "hidden";};

const handleDrop = (e: DragEvent) => {
  e.preventDefault();
  if (e.dataTransfer.files.length < 1) return;
  loadVideo(e.dataTransfer.files[0])
  hideDropZone();
}
const allowDrag = (e: DragEvent) => {
  if (e.dataTransfer.types.length != 1 || e.dataTransfer.types[0] != 'Files') return;
  e.dataTransfer.dropEffect = "copy";
  e.preventDefault();
}

window.addEventListener('dragenter', showDropZone);
dom.dropZone.addEventListener('dragenter', allowDrag);
dom.dropZone.addEventListener('dragover', allowDrag);
dom.dropZone.addEventListener('dragleave', hideDropZone);
dom.dropZone.addEventListener('drop', handleDrop);

// window.addEventListener("load", () => {

// });


// document.getElementById("export").onclick = window.videoAPI.