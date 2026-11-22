// Firebase Auth — única identidad (misma cuenta que la APK).
// El acceso a datos privados en Supabase irá vía worker penalex-auth-bridge.
"use client";

import { initializeApp, getApps, type FirebaseApp } from "firebase/app";
import {
  getAuth,
  signInWithPopup,
  signInWithRedirect,
  getRedirectResult,
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

/** Inicia sesión con Google. Intenta popup y, si el navegador lo bloquea
 *  o el entorno no lo soporta, cae a redirección completa (más fiable en web).
 *  Devuelve null cuando se inició una redirección (la página se recarga). */
export async function loginGoogle(): Promise<User | null> {
  const a = authRequerida();
  const provider = new GoogleAuthProvider();
  provider.setCustomParameters({ prompt: "select_account" });
  try {
    const cred = await signInWithPopup(a, provider);
    return cred.user;
  } catch (e: unknown) {
    const code = (e as { code?: string })?.code ?? "";
    console.error("[loginGoogle] popup falló:", code, e);
    const caerARedirect =
      code === "auth/popup-blocked" ||
      code === "auth/popup-closed-by-user" ||
      code === "auth/cancelled-popup-request" ||
      code === "auth/operation-not-supported-in-this-environment" ||
      code === "auth/web-storage-unsupported" ||
      code === "auth/internal-error";
    if (caerARedirect) {
      await signInWithRedirect(a, provider);
      return null;
    }
    throw e;
  }
}

/** Completa el login si se volvió de una redirección de Google. */
export async function resultadoRedirect(): Promise<User | null> {
  const a = auth();
  if (!a) return null;
  try {
    const r = await getRedirectResult(a);
    return r?.user ?? null;
  } catch (e) {
    console.error("[resultadoRedirect] error:", e);
    return null;
  }
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