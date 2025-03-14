function removeAds() {
  document.querySelectorAll('.grid.grid-cols-1.md\\:grid-cols-2.md\\:gap-4.gap-4').forEach(el => el.remove());

  if (window.location.pathname.startsWith('/chapter/')) {
    document.querySelectorAll('.fixed.bottom-0.left-0.w-screen.h-\\[calc\\(100dvh\\)\\].md\\:h-screen.bg-base-bg\\/40.z-\\[208\\].flex.flex-col.justify-end.items-start').forEach(el => el.remove());

    document.querySelectorAll('.max-w-800.mx-auto.w-full.pb-12.lg\\:pb-12.relative.z-\\[207\\]').forEach(el => el.remove());

    // Hapus elemen Disqus jika berada di halaman /chapter/
    const disqusThread = document.getElementById('disqus_thread');
    if (disqusThread) {
      disqusThread.remove();
    }
  }
}

function modifyNavbar() {
  if (window.location.pathname.startsWith('/chapter/')) {
    return; // Jangan modifikasi navbar jika di halaman /chapter/
  }

  const navbar = document.querySelector('.md\\:px-64.px-16.md\\:py-24.py-16.lg\\:h-100.transition-all.bg-base-bg.border-b.border-base-white\\/10.flex');
  if (navbar) {
    navbar.style.height = '95px';

    const firstChild = navbar.querySelector(':first-child');
    if (firstChild) {
      firstChild.style.paddingTop = '25px';
    }
  }
}

// Jalankan fungsi awal
removeAds();
modifyNavbar();

const observer = new MutationObserver(mutations => {
  mutations.forEach(mutation => {
    mutation.addedNodes.forEach(node => {
      if (node.nodeType === 1) {
        // Hapus iklan jika elemen baru sesuai dengan selektor
        if (node.matches('.grid.grid-cols-1.md\\:grid-cols-2.md\\:gap-4.gap-4')) {
          node.remove();
        }

        if (window.location.pathname.startsWith('/chapter/')) {
          if (node.matches('.fixed.bottom-0.left-0.w-screen.h-\\[calc\\(100dvh\\)\\].md\\:h-screen.bg-base-bg\\/40.z-\\[208\\].flex.flex-col.justify-end.items-start')) {
            node.remove();
          }
          if (node.matches('.max-w-800.mx-auto.w-full.pb-12.lg\\:pb-12.relative.z-\\[207\\]')) {
            node.remove();
          }
          if (node.id === "disqus_thread") {
            node.remove();
          }
        } else {
          // Modifikasi navbar hanya jika bukan halaman /chapter/
          if (node.matches('.md\\:px-64.px-16.md\\:py-24.py-16.lg\\:h-100.transition-all.bg-base-bg.border-b.border-base-white\\/10.flex')) {
            node.style.height = '95px';

            const firstChild = node.querySelector(':first-child');
            if (firstChild) {
              firstChild.style.paddingTop = '25px';
            }
          }
        }
      }
    });
  });
});

observer.observe(document.body, { childList: true, subtree: true });

function checkScroll() {
  if (window.location.pathname.startsWith('/chapter/')) {
    if ((window.innerHeight + window.scrollY) >= document.body.offsetHeight + 70) {
      if (!document.getElementById('loading-indicator')) {
        let loader = document.createElement('div');
        loader.id = 'loading-indicator';
        loader.style.position = 'fixed';
        loader.style.bottom = '20px';
        loader.style.left = '50%';
        loader.style.transform = 'translateX(-50%)';
        loader.style.background = 'rgba(0, 0, 0, 0.7)';
        loader.style.color = 'white';
        loader.style.padding = '10px 20px';
        loader.style.borderRadius = '10px';
        loader.style.fontSize = '14px';
        loader.innerText = 'Loading next page...';
        document.body.appendChild(loader);

        setTimeout(() => {
          loader.remove();
          goToNextChapter();
        }, 1100);
      }
    }
  }
}

function goToNextChapter() {
  document.querySelectorAll('.md\\:w-64.w-48.aspect-square.rounded-full.bg-base-card').forEach(button => {
    const svg = button.querySelector('svg[width="24"][height="24"][viewBox="0 0 40 40"][xmlns="http://www.w3.org/2000/svg"]');
    if (svg) {
      button.click(); // Klik tombol "Next Chapter"
    }
  });
}

window.addEventListener('scroll', checkScroll);