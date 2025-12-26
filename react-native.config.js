// react-native-noke/react-native.config.js
module.exports = {
  dependency: {
    platforms: {
      android: {
        packageImportPath: 'import com.nmhnoke.NokePackage;',
        packageInstance: 'new NokePackage()',
      },
    },
  },
};