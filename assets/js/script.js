const SELECTORS = {
  ads: ".grid.grid-cols-1.md\\:grid-cols-2.md\\:gap-4.gap-4",
  bottomOverlay:
    ".fixed.bottom-0.left-0.w-screen.h-\\[calc\\(100dvh\\)\\].md\\:h-screen.bg-base-bg\\/40.z-\\[208\\].flex.flex-col.justify-end.items-start",
  bottomContent:
    ".max-w-800.mx-auto.w-full.pb-12.lg\\:pb-12.relative.z-\\[207\\]",
  navbar:
    ".md\\:px-64.px-16.md\\:py-24.py-16.lg\\:h-100.transition-all.bg-base-bg.border-b.border-base-white\\/10.flex",
};

function isChapterPage() {
  return window.location.pathname.startsWith("/chapter/");
}

let isShowingLoadingIndicator = false;

function removeAds() {
  document.querySelectorAll(SELECTORS.ads).forEach((el) => el.remove());

  if (isChapterPage()) {
    document
      .querySelectorAll(SELECTORS.bottomOverlay)
      .forEach((el) => el.remove());
    document
      .querySelectorAll(SELECTORS.bottomContent)
      .forEach((el) => el.remove());

    const disqusThread = document.getElementById("disqus_thread");
    if (disqusThread) {
      disqusThread.remove();
    }
  }
}

function modifyNavbar() {
  if (isChapterPage()) return;

  const navbar = document.querySelector(SELECTORS.navbar);
  if (!navbar) return;

  navbar.style.height = "95px";

  const firstChild = navbar.querySelector(":first-child");
  if (firstChild) {
    firstChild.style.paddingTop = "25px";
  }
}

function handleNewNode(node) {
  if (node.nodeType !== 1) return;
  if (node.matches(SELECTORS.ads)) {
    node.remove();
    return;
  }

  const onChapterPage = isChapterPage();

  if (onChapterPage) {
    if (
      node.matches(SELECTORS.bottomOverlay) ||
      node.matches(SELECTORS.bottomContent) ||
      node.id === "disqus_thread"
    ) {
      node.remove();
    }
  } else {
    if (node.matches(SELECTORS.navbar)) {
      node.style.height = "95px";

      const firstChild = node.querySelector(":first-child");
      if (firstChild) {
        firstChild.style.paddingTop = "25px";
      }
    }
  }
}

function init() {
  removeAds();
  modifyNavbar();

  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      mutation.addedNodes.forEach(handleNewNode);
    });
  });

  observer.observe(document.body, { childList: true, subtree: true });
  const pushState = history.pushState;
  history.pushState = function () {
    pushState.apply(history, arguments);

    setTimeout(() => {
      removeAds();
      modifyNavbar();
    }, 300);
  };

  window.addEventListener("popstate", () => {
    setTimeout(() => {
      removeAds();
      modifyNavbar();
    }, 300);
  });
}

init();
