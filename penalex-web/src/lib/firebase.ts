// Firebase Auth — única identidad (misma cuenta que la APK).
// El acceso a datos privados en Supabase irá vía worker penalex-auth-bridge.
"use client";

import { initializeApp, getApps, type FirebaseApp } from "firebase/app";
import {
  getAuth,
  signInWithPopup,
  GoogleAuthProvider,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut as fbSignOut,
  updateProfile,
  onAuthStateChanged,
  type User,
} from "firebase/auth";

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID,
};

/** true solo si el build recibió las claves públicas de Firebase.
 *  Si faltan, la web debe seguir funcionando (sin login), nunca romperse. */
export const firebaseConfigurado = Boolean(
  process.env.NEXT_PUBLIC_FIREBASE_API_KEY &&
    process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID
);

export function getFirebaseApp(): FirebaseApp {
  if (!firebaseConfigurado) {
    throw new Error(
      "Firebase no configurado: faltan NEXT_PUBLIC_FIREBASE_* en el build."
    );
  }
  if (getApps().length === 0) {
    return initializeApp(firebaseConfig);
  }
  return getApps()[0];
}

export const auth = () => {
  if (!firebaseConfigurado) return null;
  return getAuth(getFirebaseApp());
};

function authRequerida() {
  const a = auth();
  if (!a) {
    throw new Error(
      "El inicio de sesión no está disponible: configura Firebase en el despliegue."
    );
  }
  return a;
}

export async function loginGoogle(): Promise<User> {
  const provider = new GoogleAuthProvider();
  const cred = await signInWithPopup(authRequerida(), provider);
  return cred.user;
}

export async function loginEmail(email: string, password: string): Promise<User> {
  const cred = await signInWithEmailAndPassword(authRequerida(), email, password);
  return cred.user;
}

export async function registrarEmail(
  email: string,
  password: string,
  nombre?: string
): Promise<User> {
  const cred = await createUserWithEmailAndPassword(authRequerida(), email, password);
  if (nombre) {
    try {
      await updateProfile(cred.user, { displayName: nombre });
    } catch {
      // el displayName es opcional; no bloquea el registro
    }
  }
  return cred.user;
}

export async function cerrarSesion(): Promise<void> {
  const a = auth();
  if (a) await fbSignOut(a);
}

export function escucharAuth(cb: (u: User | null) => void): () => void {
  const a = auth();
  if (!a) {
    // Sin Firebase configurado no hay sesión: se notifica "sin usuario".
    cb(null);
    return () => {};
  }
  return onAuthStateChanged(a, cb);
}