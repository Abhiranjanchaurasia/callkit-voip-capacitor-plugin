import { WebPlugin, PluginListenerHandle } from '@capacitor/core';

import type { CallKitVoipPlugin, CallData } from './definitions';

export class CallKitVoipWeb extends WebPlugin implements CallKitVoipPlugin {
  async register(): Promise<void> {
    console.log('call is register');
    return;
  }

  async show_call_notification(callData: CallData): Promise<void> {
    console.log('call is register', callData);
    return;
  }

  async abortCall(): Promise<void> {
    console.log('call is aborted');
    return;
  }


  addListener(eventName: string, _callback: (data: any) => void): Promise<PluginListenerHandle> & PluginListenerHandle {
    const handle: PluginListenerHandle = {
      remove: async () => {
        console.log(`Listener for ${eventName} removed`);
        return;
      },
    };

    const promise = new Promise<PluginListenerHandle>((resolve) => {
      // Simulate async listener setup
      setTimeout(() => {
        console.log(`Listener for ${eventName} added`);
        resolve(handle);
      }, 100);
    });

    return Object.assign(promise, handle);
  }
  

}
