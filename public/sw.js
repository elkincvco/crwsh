const CACHE_NAME = 'carwash-pro-v1'
const STATIC_CACHE_NAME = 'carwash-pro-static-v1'
const DYNAMIC_CACHE_NAME = 'carwash-pro-dynamic-v1'

// Files to cache immediately
const STATIC_FILES = [
  '/',
  '/index.html',
  '/src/main.tsx',
  '/src/index.css',
  '/manifest.json',
  '/offline.html'
]

// API endpoints to cache
const API_CACHE_PATTERNS = [
  /\/api\/appointments/,
  /\/api\/notifications/,
  /\/api\/workspaces/
]

// Install event - cache static files
self.addEventListener('install', (event) => {
  console.log('🔧 Service Worker: Installing...')
  
  event.waitUntil(
    caches.open(STATIC_CACHE_NAME)
      .then((cache) => {
        console.log('📦 Service Worker: Caching static files')
        return cache.addAll(STATIC_FILES)
      })
      .then(() => {
        console.log('✅ Service Worker: Static files cached')
        return self.skipWaiting()
      })
  )
})

// Activate event - clean old caches
self.addEventListener('activate', (event) => {
  console.log('🚀 Service Worker: Activating...')
  
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (cacheName !== STATIC_CACHE_NAME && cacheName !== DYNAMIC_CACHE_NAME) {
              console.log('🗑️ Service Worker: Deleting old cache:', cacheName)
              return caches.delete(cacheName)
            }
          })
        )
      })
      .then(() => {
        console.log('✅ Service Worker: Activated')
        return self.clients.claim()
      })
  )
})

// Fetch event - serve from cache or network
self.addEventListener('fetch', (event) => {
  const { request } = event
  const url = new URL(request.url)

  // Skip non-GET requests
  if (request.method !== 'GET') {
    return
  }

  // Handle different types of requests
  if (request.url.includes('/api/') || request.url.includes('supabase.co')) {
    // API requests - Network first, then cache
    event.respondWith(networkFirstStrategy(request))
  } else if (STATIC_FILES.some(file => request.url.endsWith(file))) {
    // Static files - Cache first
    event.respondWith(cacheFirstStrategy(request))
  } else {
    // Other requests - Stale while revalidate
    event.respondWith(staleWhileRevalidateStrategy(request))
  }
})

// Cache first strategy (for static files)
async function cacheFirstStrategy(request) {
  try {
    const cachedResponse = await caches.match(request)
    if (cachedResponse) {
      return cachedResponse
    }

    const networkResponse = await fetch(request)
    if (networkResponse.ok) {
      const cache = await caches.open(STATIC_CACHE_NAME)
      cache.put(request, networkResponse.clone())
    }
    return networkResponse
  } catch (error) {
    console.error('Cache first strategy failed:', error)
    return caches.match('/offline.html')
  }
}

// Network first strategy (for API calls)
async function networkFirstStrategy(request) {
  try {
    const networkResponse = await fetch(request)
    if (networkResponse.ok) {
      const cache = await caches.open(DYNAMIC_CACHE_NAME)
      cache.put(request, networkResponse.clone())
    }
    return networkResponse
  } catch (error) {
    console.log('Network failed, trying cache:', request.url)
    const cachedResponse = await caches.match(request)
    if (cachedResponse) {
      return cachedResponse
    }
    
    // Return offline page for navigation requests
    if (request.mode === 'navigate') {
      return caches.match('/offline.html')
    }
    
    throw error
  }
}

// Stale while revalidate strategy
async function staleWhileRevalidateStrategy(request) {
  const cache = await caches.open(DYNAMIC_CACHE_NAME)
  const cachedResponse = await cache.match(request)

  const fetchPromise = fetch(request).then((networkResponse) => {
    if (networkResponse.ok) {
      cache.put(request, networkResponse.clone())
    }
    return networkResponse
  }).catch(() => cachedResponse)

  return cachedResponse || fetchPromise
}

// Push notification event
self.addEventListener('push', (event) => {
  console.log('🔔 Push notification received:', event)
  
  if (!event.data) {
    return
  }

  const data = event.data.json()
  console.log('📱 Push data:', data)

  const options = {
    body: data.message || 'Nueva notificación',
    icon: '/icons/icon-192x192.png',
    badge: '/icons/icon-72x72.png',
    tag: data.type || 'general',
    data: {
      url: data.url || '/',
      appointmentId: data.appointmentId,
      type: data.type
    },
    actions: [
      {
        action: 'view',
        title: 'Ver',
        icon: '/icons/icon-72x72.png'
      },
      {
        action: 'dismiss',
        title: 'Cerrar'
      }
    ],
    requireInteraction: true,
    silent: false
  }

  event.waitUntil(
    self.registration.showNotification(data.title || 'CarWash Pro', options)
  )
})

// Notification click event
self.addEventListener('notificationclick', (event) => {
  console.log('🖱️ Notification clicked:', event)
  
  event.notification.close()

  if (event.action === 'dismiss') {
    return
  }

  const urlToOpen = event.notification.data?.url || '/'

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        // Check if app is already open
        for (const client of clientList) {
          if (client.url.includes(urlToOpen) && 'focus' in client) {
            return client.focus()
          }
        }
        
        // Open new window/tab
        if (clients.openWindow) {
          return clients.openWindow(urlToOpen)
        }
      })
  )
})

// Background sync event (for offline actions)
self.addEventListener('sync', (event) => {
  console.log('🔄 Background sync:', event.tag)
  
  if (event.tag === 'background-sync-appointments') {
    event.waitUntil(syncAppointments())
  }
})

// Sync appointments when back online
async function syncAppointments() {
  try {
    console.log('🔄 Syncing appointments...')
    // Here you would implement the sync logic
    // For now, just log that sync would happen
    console.log('✅ Appointments synced')
  } catch (error) {
    console.error('❌ Sync failed:', error)
  }
}

// Message event (for communication with main thread)
self.addEventListener('message', (event) => {
  console.log('💬 Message received:', event.data)
  
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting()
  }
})
