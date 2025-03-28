const SubmitDecrypt = {
  mounted() {
    const targetNode = this.el;
    targetNode.addEventListener("keypress", function (event) {
      if (event.key === "Enter") {
        event.preventDefault();
        document.getElementById("decrypt-btn").click();
      }
    });
  },
};
export default SubmitDecrypt;
