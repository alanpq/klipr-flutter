
const getRegionDOM = () => {
  const parent = document.querySelector("#time > .region") as HTMLElement;
  return {
    parent,
    a: parent.firstElementChild,
    b: parent.lastElementChild,
  }
}

const controls = {
  play: document.getElementById("play"),
  mute: document.getElementById("mute"),
  volume: document.getElementById("volume") as HTMLInputElement,
  timestamp: document.getElementById("timestamp"),

  cursor: document.querySelector("#time > .cursor") as HTMLElement,
  timeline: document.querySelector("#time"),
  region: getRegionDOM(),
}

const callbacks: {
  mute: () => void,
  play: () => void,
  volume: (volume: number) => void,
  seek: (time: number) => void,
} = {
  mute: null,
  play: null,
  volume: null,
  seek: null,
};

export const onMute = (cb: () => void) => {
  callbacks.mute = cb;
}

export const onPlay = (cb: () => void) => {
  callbacks.play = cb;
}

export const onVolume = (cb: (volume: number) => void) => {
  callbacks.volume = cb;
}

export const onSeek = (cb: (time: number) => void) => {
  callbacks.seek = cb;
}

export const updateTime = (time: number) => {
  controls.cursor.style.left = time * regionState.rect.width + 'px';
}

controls.play.onclick = () => {
  callbacks.play();
}

controls.mute.onclick = () => {
  callbacks.mute();
}

controls.volume.onchange = (e) => {
  callbacks.volume(controls.volume.valueAsNumber / 100);
}

const regionState = {
  start: 0,
  end: 1,

  held: "",

  regionRect: new DOMRect(),
  rect: new DOMRect(),
}

regionState.regionRect = controls.region.parent.getClientRects()[0];
regionState.rect = controls.timeline.getClientRects()[0];

const mouseDown = (e: Event, target: string) => {
  e.preventDefault();
  if(regionState.held !== "time" && regionState.held !== "") return; // time will always be overwitten by start or end
  console.log('down', target);
  regionState.held = target;
}

const mouseUp = () => {
  console.log('up');
  regionState.held = "";
}

const clamp = (x: number, min: number, max: number) => {
  return (x < min) ? min : ((x > max) ? max : x)
}

const mouseMove = (e: MouseEvent) => {
  if (regionState.held === "") return;

  const x = clamp(e.clientX - regionState.rect.x, 0, regionState.rect.width);
  const scaledX = x / regionState.rect.width;

  switch (regionState.held) {
    case "start": (() => {
      regionState.start = scaledX;
      const width = (regionState.rect.width * regionState.end) - x;
      controls.region.parent.style.marginLeft = x + "px";
      controls.region.parent.style.width = width + "px";
      })()
    break;
    case "end": (() => {
      const width = x - (regionState.rect.width * regionState.start);
      controls.region.parent.style.width = width + "px";
      regionState.end = scaledX;
      })()
    break;
    case "time": (() => {
      
    })()
    break;
  }
  callbacks.seek(scaledX)
}

const registerRegionEvents = (handle: Node, target: string) => {
  handle.addEventListener("mousedown", (e: MouseEvent) => {mouseDown(e, target)}, {capture: true});
}
registerRegionEvents(controls.region.a, "start");
registerRegionEvents(controls.region.b, "end");
registerRegionEvents(controls.timeline, "time");

window.addEventListener("mousemove", mouseMove);
window.addEventListener("mouseup", mouseUp);