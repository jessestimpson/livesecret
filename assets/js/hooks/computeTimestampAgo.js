function getTimeString(dateLocal) {
  //return `${dateLocal}`;
  return dateLocal.toLocaleString(navigator.language, {
    hour: "numeric",
    minute: "numeric",
    hour12: true,
  });
}

function getAgoString(dateLocal, formatFor) {
  const nowLocal = new Date();

  const diff = nowLocal.getTime() - dateLocal.getTime();
  const seconds = Math.floor(diff / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);
  const months = Math.floor(days / 30);
  const years = Math.floor(months / 12);

  let ago = "";
  if (years > 0) {
    ago = `${years} year${years > 1 ? "s" : ""} ago`;
  } else if (months > 0) {
    ago = `${months} month${months > 1 ? "s" : ""} ago`;
  } else if (days > 0) {
    ago = `${days} day${days > 1 ? "s" : ""} ago`;
  } else if (hours > 0) {
    ago = `${hours} hour${hours > 1 ? "s" : ""} ago`;
  } else if (minutes > 0) {
    ago = `${minutes} minute${minutes > 1 ? "s" : ""} ago`;
  } else {
    if (formatFor == "admin")
      ago = `${seconds} second${seconds == 0 || seconds > 1 ? "s" : ""} ago`;
    else ago = "less than a minute ago";
  }

  const timeString = getTimeString(dateLocal);
  return `${timeString} (${ago})`;
}

const ComputeTimestampAgo = {
  mounted() {
    const targetNode = this.el;

    const datetime = targetNode.getAttribute("data-datetime");
    const formatFor = targetNode.getAttribute("data-format-for");
    const dateLocal = new Date(`${datetime}Z`);

    ago = getAgoString(dateLocal, formatFor);
    targetNode.textContent = ago;

    setInterval(() => {
      ago = getAgoString(dateLocal, formatFor);
      targetNode.textContent = ago;
    }, 1000);
  },
  updated() {
    const targetNode = this.el;

    const datetime = targetNode.getAttribute("data-datetime");
    const formatFor = targetNode.getAttribute("data-format-for");
    const dateLocal = new Date(`${datetime}Z`);

    ago = getAgoString(dateLocal, formatFor);
    targetNode.textContent = ago;
  },
};

export default ComputeTimestampAgo;
