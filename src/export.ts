const sizeForm = document.getElementById("filesizeForm") as HTMLFormElement;
const otherSize = document.getElementById("other_size") as HTMLInputElement;
const size = sizeForm.elements.namedItem("size") as RadioNodeList;


const init = () => {
  for(let i = 0; i < sizeForm.elements.length; i++) {
    sizeForm.elements[i].addEventListener("change", () => {
      if(size.value == "other") otherSize.disabled = false;
      else otherSize.disabled = true;
    });
  }
  
}


const getSize = () => {
  if(size.value == "other") return otherSize.valueAsNumber;
  return parseInt(size.value, 10);
}

init();

document.getElementById("share").onclick = () => {
  (<any>window).videoAPI.exportVideo(state.file, getSize());
};