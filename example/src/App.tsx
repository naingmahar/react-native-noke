import { useEffect, useState } from 'react';
import { Text, View, StyleSheet, NativeEventEmitter, NativeModules } from 'react-native';
import Noke from 'react-native-noke';
import type { NokeUpdateEvent } from '../../src/NativeNoke';


// --- Event Emitter Setup (UPDATED) ---


const { NativeRNNoke } = NativeModules;
const nokeEmitter = new NativeEventEmitter(NativeRNNoke);

export default function App() {

    const [lastEvent, setLastEvent] = useState<NokeUpdateEvent | null>(null);
    const [log, setLog] = useState<NokeUpdateEvent[]>([]);

    useEffect(() => {
      // 1. SET UP LISTENERS FIRST
    const subscription = nokeEmitter.addListener('nokeServiceUpdated', (event) => {
        console.log('Noke Event Received:', event);
    });

      // Initialize the native code via the NokeModuleImpl turbo module
        Noke.initNoke("dba1586f-2992-442d-a4e7-970b43ee420d","com.extraspaceasia.loyalty");
        // Cleanup function runs on component unmount
        return () => {
            subscription.remove(); 
        };
    }, []);

  return (
    <View style={styles.container}>
      <Text>Result: {JSON.stringify(lastEvent)}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
