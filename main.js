import { supabase } from './src/supabaseClient.js';

// --- Core UI Functionality ---

// Mobile menu
const mobileMenuBtn = document.getElementById('mobile-menu-btn');
const mobileMenu = document.getElementById('mobile-menu');
if (mobileMenuBtn && mobileMenu) {
  mobileMenuBtn.addEventListener('click', () => {
    mobileMenu.classList.toggle('hidden');
  });
}

// Smooth scrolling for navigation links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', function (e) {
    e.preventDefault();
    const target = document.querySelector(this.getAttribute('href'));
    if (target) {
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      if (mobileMenu) mobileMenu.classList.add('hidden');
    }
  });
});

// Navbar background change on scroll
window.addEventListener('scroll', () => {
  const nav = document.querySelector('nav');
  if (nav && window.scrollY > 100) {
    nav.classList.add('bg-white/95', 'backdrop-blur-sm');
  } else if (nav) {
    nav.classList.remove('bg-white/95', 'backdrop-blur-sm');
  }
});

// --- Supabase Integration ---

// Auth State Change Handler
supabase.auth.onAuthStateChange(async (event, session) => {
  const loginBtn = document.getElementById('loginBtn');
  if (!loginBtn) return;

  if (event === 'SIGNED_IN' && session?.user) {
    const { data: profiles, error } = await supabase
      .from('profiles')
      .select('full_name, role')
      .eq('id', session.user.id);
    
    if (error) {
      console.error("Error fetching profile on auth state change:", error);
      return;
    }

    if (profiles && profiles.length > 0) {
      const profile = profiles[0]; // Use the first profile if duplicates exist
      loginBtn.textContent = profile.full_name || 'Dashboard';
      loginBtn.href = '#';
      loginBtn.onclick = (e) => {
        e.preventDefault();
        const role = profile.role;
        if (role === 'admin') window.location.href = 'admin-dashboard.html';
        else if (role === 'user') window.location.href = 'user-dashboard.html';
        else if (role === 'mitra') window.location.href = 'mitra-dashboard.html';
        else window.location.href = 'login.html';
      };
    }
  } else if (event === 'SIGNED_OUT') {
    loginBtn.textContent = 'Masuk';
    loginBtn.href = 'login.html';
    loginBtn.onclick = null;
  }
});


// Load products from Supabase
async function loadProducts(filterCategory = 'all') {
  const productGrid = document.getElementById('product-grid');
  if (!productGrid) return;
  
  productGrid.innerHTML = '<p class="text-center col-span-full">Memuat produk...</p>';

  let query;

  if (filterCategory !== 'all') {
    query = supabase
      .from('products')
      .select('*, categories!inner(slug)') // Use inner join to filter
      .eq('categories.slug', filterCategory);
  } else {
    query = supabase
      .from('products')
      .select('*'); // Select all products
  }

  const { data: products, error } = await query;

  if (error) {
    productGrid.innerHTML = `<p class="text-center col-span-full text-red-500">Gagal memuat produk: ${error.message}</p>`;
    console.error("Supabase error:", error);
    return;
  }

  if (products.length === 0) {
    productGrid.innerHTML = '<p class="text-center col-span-full">Tidak ada produk ditemukan untuk kategori ini.</p>';
    return;
  }

  productGrid.innerHTML = products.map(product => {
    const imageUrl = (product.image_urls && product.image_urls.length > 0) 
      ? product.image_urls[0] 
      : 'https://img-wrapper.vercel.app/image?url=https://img-wrapper.vercel.app/image?url=https://img-wrapper.vercel.app/image?url=https://placehold.co/300x300';
    
    const stockStatus = product.stock > 5
      ? `<span class="absolute top-2 right-2 bg-green-100 text-green-800 text-xs font-medium px-2.5 py-0.5 rounded-full">Stok Tersedia</span>`
      : product.stock > 0
      ? `<span class="absolute top-2 right-2 bg-gold-100 text-gold-800 text-xs font-medium px-2.5 py-0.5 rounded-full">Stok Terbatas: ${product.stock}</span>`
      : `<span class="absolute top-2 right-2 bg-red-100 text-red-800 text-xs font-medium px-2.5 py-0.5 rounded-full">Habis</span>`;

    return `
    <div class="card group cursor-pointer transform hover:scale-105 transition-all duration-300">
      <div class="relative overflow-hidden">
        <img src="${imageUrl}" alt="${product.name}" class="w-full h-64 object-cover group-hover:scale-110 transition-transform duration-300">
        <div class="absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-10 transition-all duration-300"></div>
        ${stockStatus}
      </div>
      <div class="p-6">
        <div class="flex text-gold-400 mb-2">
          ${'★'.repeat(Math.round(product.rating || 0))}${'☆'.repeat(5 - Math.round(product.rating || 0))}
        </div>
        <h3 class="text-lg font-semibold text-earth-800 mb-2 group-hover:text-natural-600 transition-colors">${product.name}</h3>
        <p class="text-earth-600 text-sm mb-4">${product.description}</p>
        <div class="flex items-center justify-between">
          <span class="text-xl font-bold text-natural-600">Rp ${Number(product.price).toLocaleString('id-ID')}</span>
          <button class="btn-primary text-sm px-4 py-2 ${product.stock === 0 ? 'opacity-50 cursor-not-allowed' : ''}" ${product.stock === 0 ? 'disabled' : ''}>
            ${product.stock === 0 ? 'Stok Habis' : 'Tambah ke Keranjang'}
          </button>
        </div>
      </div>
    </div>
  `}).join('');
}

// Category filter functionality
document.querySelectorAll('.category-btn').forEach(btn => {
  btn.addEventListener('click', (e) => {
    document.querySelectorAll('.category-btn').forEach(b => {
      b.classList.remove('bg-natural-600', 'text-white');
      b.classList.add('bg-white', 'text-earth-600');
    });
    
    e.target.classList.add('bg-natural-600', 'text-white');
    e.target.classList.remove('bg-white', 'text-earth-600');
    
    const slug = e.target.dataset.slug;
    loadProducts(slug);
  });
});

// Initialize products on page load
if (document.getElementById('product-grid')) {
  loadProducts();
}


// --- Other Functionality ---

// Contact form submission
const contactForm = document.querySelector('#contact form');
if (contactForm) {
  contactForm.addEventListener('submit', (e) => {
    e.preventDefault();
    alert('Terima kasih! Pesan Anda telah terkirim.');
    e.target.reset();
  });
}

// Add to cart notification
document.addEventListener('click', (e) => {
  if (e.target.matches('.btn-primary') && e.target.textContent.includes('Tambah ke Keranjang')) {
    e.preventDefault();
    const notification = document.createElement('div');
    notification.className = 'fixed top-20 right-4 bg-natural-600 text-white px-6 py-3 rounded-lg shadow-lg z-50 animate-fade-in';
    notification.textContent = 'Produk berhasil ditambahkan ke keranjang!';
    document.body.appendChild(notification);
    setTimeout(() => {
      notification.remove();
    }, 3000);
  }
});

// WhatsApp integration
function openWhatsApp(message = '') {
  const phoneNumber = '6281354803858';
  const encodedMessage = encodeURIComponent(message || 'Halo, saya tertarik dengan produk Alatacrat');
  const whatsappUrl = `https://wa.me/${phoneNumber}?text=${encodedMessage}`;
  window.open(whatsappUrl, '_blank');
}
window.openWhatsApp = openWhatsApp; // Make it globally accessible for inline onclick

if (!document.querySelector('.whatsapp-float')) {
  const whatsappFloat = document.createElement('div');
  whatsappFloat.className = 'whatsapp-float fixed bottom-6 right-6 z-50';
  whatsappFloat.innerHTML = `
    <button onclick="openWhatsApp()" class="bg-green-500 hover:bg-green-600 text-white p-4 rounded-full shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-110">
      <svg class="w-6 h-6" fill="currentColor" viewBox="0 0 24 24"><path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893A11.821 11.821 0 0020.885 3.488"/></svg>
    </button>
  `;
  document.body.appendChild(whatsappFloat);
}
