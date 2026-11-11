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

export function getFirebaseApp(): FirebaseApp {
  if (getApps().length === 0) {
    return initializeApp(firebaseConfig);
  }
  return getApps()[0];
}

export const auth = () => getAuth(getFirebaseApp());

export async function loginGoogle(): Promise<User> {
  const provider = new GoogleAuthProvider();
  const cred = await signInWithPopup(auth(), provider);
  return cred.user;
}

export async function loginEmail(email: string, password: string): Promise<User> {
  const cred = await signInWithEmailAndPassword(auth(), email, password);
  return cred.user;
}

export async function registrarEmail(
  email: string,
  password: string,
  nombre?: string
): Promise<User> {
  const cred = await createUserWithEmailAndPassword(auth(), email, password);
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
  await fbSignOut(auth());
}

export function escucharAuth(cb: (u: User | null) => void): () => void {
  return onAuthStateChanged(auth(), cb);
}