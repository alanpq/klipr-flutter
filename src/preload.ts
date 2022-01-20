import {contextBridge, ipcRenderer} from 'electron'; 
import * as path from 'path';

// All of the Node.js APIs are available in the preload process.
// It has the same sandbox as a Chrome extension.
window.addEventListener("DOMContentLoaded", () => {
  const replaceText = (selector: string, text: string) => {
    const element = document.getElementById(selector);
    if (element) {
      element.innerText = text;
    }
  };

  for (const type of ["chrome", "node", "electron"]) {
    replaceText(`${type}-version`, process.versions[type as keyof NodeJS.ProcessVersions]);
  }
});

contextBridge.exposeInMainWorld('electron', {
  startDrag: (fileName: string) => {
    ipcRenderer.send('ondragstart', path.join(process.cwd(), fileName))
  }
})

contextBridge.exposeInMainWorld('videoAPI', {
  exportVideo: (size: number, fileName: string) => {
    ipcRenderer.send('videoExport', fileName, size)
  }
})