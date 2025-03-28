const OnIncorrectPassphrase = {
  mounted() {
    console.log("OnIncorrectPassphrase mounted");

    // Select the node that will be observed for mutations
    const targetNode = this.el;

    // Options for the observer (which mutations to observe)
    const config = { childList: true };

    // Callback function to execute when mutations are observed
    const callback = (mutationList, observer) => {
      for (const mutation of mutationList) {
        if (mutation.type === "childList") {
          console.log(
            `A child node has been added or removed. ${targetNode.textContent}`,
          );
        }
      }
    };

    // Create an observer instance linked to the callback function
    const observer = new MutationObserver(callback);

    // Start observing the target node for configured mutations
    observer.observe(targetNode, config);
  },
};
export default OnIncorrectPassphrase;
