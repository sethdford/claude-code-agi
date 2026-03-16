# React Native Conventions

This preset covers best practices for React Native projects with navigation, state, testing, and performance optimization.

## Expo vs Bare Workflow

Use Expo for rapid development and prototyping. Use bare workflow only when you need native modules.

**Pattern (Expo):**

```bash
npx create-expo-app MyApp
cd MyApp
npx expo start
```

**Benefits:**
- No native code required
- Instant preview via Expo app
- OTA (Over-The-Air) updates
- Simplified deployment

**Bare workflow (when needed):**

```bash
npx react-native init MyApp
cd MyApp
npm start
```

Use Expo Go for development even in bare workflow projects when possible.

## Navigation with React Navigation

Use React Navigation for all routing. Configure stack, tab, and drawer navigators.

**Pattern (Stack Navigator):**

```typescript
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import HomeScreen from './screens/HomeScreen';
import DetailScreen from './screens/DetailScreen';

const Stack = createNativeStackNavigator();

export default function RootNavigator() {
  return (
    <NavigationContainer>
      <Stack.Navigator>
        <Stack.Screen
          name="Home"
          component={HomeScreen}
          options={{ title: 'My Home' }}
        />
        <Stack.Screen
          name="Detail"
          component={DetailScreen}
          options={({ route }) => ({ title: route.params?.name })}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
```

**Pattern (Tab Navigator):**

```typescript
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';

const Tab = createBottomTabNavigator();

export default function TabNavigator() {
  return (
    <Tab.Navigator>
      <Tab.Screen
        name="Home"
        component={HomeScreen}
        options={{
          tabBarLabel: 'Home',
          tabBarIcon: ({ color }) => <Icon name="home" color={color} />,
        }}
      />
      <Tab.Screen name="Settings" component={SettingsScreen} />
    </Tab.Navigator>
  );
}
```

Always pass params through navigation, not props.

## State Management

Use React Context for simple state. Use Redux or Zustand for complex apps.

**Pattern (Context API):**

```typescript
import React, { createContext, useState, ReactNode } from 'react';

export const UserContext = createContext<{
  user: User | null;
  setUser: (user: User | null) => void;
} | null>(null);

export function UserProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  return (
    <UserContext.Provider value={{ user, setUser }}>
      {children}
    </UserContext.Provider>
  );
}

// Usage
export function useUser() {
  const context = React.useContext(UserContext);
  if (!context) throw new Error('useUser must be used within UserProvider');
  return context;
}
```

**Pattern (Zustand for complex apps):**

```typescript
import { create } from 'zustand';

interface AppStore {
  user: User | null;
  setUser: (user: User | null) => void;
  logout: () => void;
}

export const useAppStore = create<AppStore>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
  logout: () => set({ user: null }),
}));

// Usage
function MyComponent() {
  const user = useAppStore((state) => state.user);
  const setUser = useAppStore((state) => state.setUser);
  return <Text>{user?.name}</Text>;
}
```

Choose one state management library and stick with it. Mixing creates confusion.

## Platform-Specific Code

Use `.ios.ts` and `.android.ts` extensions or `Platform.select()`.

**Pattern (file-based):**

```
components/
├── Button.tsx
├── Button.ios.tsx      # iOS-specific
└── Button.android.tsx  # Android-specific
```

```typescript
// Button.ios.tsx
import { TouchableOpacity } from 'react-native';
export function Button() {
  return <TouchableOpacity>{/* iOS implementation */}</TouchableOpacity>;
}

// Button.android.tsx
import { Pressable } from 'react-native';
export function Button() {
  return <Pressable>{/* Android implementation */}</Pressable>;
}
```

**Pattern (Platform.select):**

```typescript
import { Platform, StyleSheet } from 'react-native';

const styles = StyleSheet.create({
  container: {
    paddingTop: Platform.select({ ios: 20, android: 0 }),
  },
});

function MyComponent() {
  return (
    <View style={styles.container}>
      {Platform.select({
        ios: <IOSSpecificComponent />,
        android: <AndroidSpecificComponent />,
      })}
    </View>
  );
}
```

Always test on both platforms when using platform-specific code.

## Testing with Jest & React Native Testing Library

Use Jest for unit tests and React Native Testing Library for component tests.

**Pattern:**

```typescript
import { render, screen, fireEvent } from '@testing-library/react-native';
import { Button } from './Button';

describe('Button', () => {
  it('renders with text', () => {
    render(<Button title="Press me" onPress={vi.fn()} />);
    expect(screen.getByText('Press me')).toBeTruthy();
  });

  it('calls onPress when clicked', () => {
    const onPress = vi.fn();
    render(<Button title="Press" onPress={onPress} />);
    fireEvent.press(screen.getByText('Press'));
    expect(onPress).toHaveBeenCalled();
  });
});
```

**jest.config.js:**

```javascript
module.exports = {
  preset: 'react-native',
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  transform: {
    '^.+\\.jsx?$': 'babel-jest',
    '^.+\\.tsx?$': 'ts-jest',
  },
  testEnvironment: 'node',
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
  ],
};
```

## Performance Optimization

**Use FlatList for long lists:**

```typescript
import { FlatList, Text, View } from 'react-native';

interface Item {
  id: string;
  name: string;
}

function ItemList({ items }: { items: Item[] }) {
  return (
    <FlatList
      data={items}
      keyExtractor={(item) => item.id}
      renderItem={({ item }) => <Text>{item.name}</Text>}
      initialNumToRender={10}
      maxToRenderPerBatch={10}
      onEndReachedThreshold={0.5}
      onEndReached={loadMore}
    />
  );
}
```

**Use memo for expensive components:**

```typescript
import { memo } from 'react';

const ExpensiveComponent = memo(({ data }: { data: Item }) => {
  return <ComplexCalculation data={data} />;
});
```

**Use useMemo for expensive calculations:**

```typescript
import { useMemo } from 'react';

function List({ items }: { items: Item[] }) {
  const sorted = useMemo(() => {
    return items.sort((a, b) => a.name.localeCompare(b.name));
  }, [items]);

  return <FlatList data={sorted} />;
}
```

## Common Mistakes

1. **Rendering long lists with ScrollView** — Always use FlatList
2. **Missing key props** — Always use stable, unique keys
3. **Heavy renders** — Use memo and useMemo for expensive components
4. **Hardcoding dimensions** — Use flex and responsive layouts
5. **Not testing on both platforms** — Always verify iOS and Android behavior
