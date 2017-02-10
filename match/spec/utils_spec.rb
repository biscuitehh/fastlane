describe Match do
  describe Match::Utils do
    describe 'import' do
      it 'finds a normal keychain name relative to ~/Library/Keychains' do
        expected_command = "security import item.path -k '#{Dir.home}/Library/Keychains/login.keychain' -P '' -T /usr/bin/codesign -T /usr/bin/security &> /dev/null"

        # this command is also sent on macOS Sierra and we need to allow it or else the test will fail
        allowed_command = "security set-key-partition-list -S apple-tool:,apple: -k \"\" #{Dir.home}/Library/Keychains/login.keychain &> /dev/null"

        allow(File).to receive(:exist?).and_return(false)
        expect(File).to receive(:exist?).with("#{Dir.home}/Library/Keychains/login.keychain").and_return(true)
        expect(File).to receive(:exist?).with('item.path').and_return(true)

        allow(FastlaneCore::Helper).to receive(:backticks).with(allowed_command, print: FastlaneCore::Globals.verbose?)
        expect(FastlaneCore::Helper).to receive(:backticks).with(expected_command, print: FastlaneCore::Globals.verbose?)

        Match::Utils.import('item.path', 'login.keychain')
      end

      it 'treats a keychain name it cannot find in ~/Library/Keychains as the full keychain path' do
        expected_command = "security import item.path -k '/my/special.keychain' -P '' -T /usr/bin/codesign -T /usr/bin/security &> /dev/null"

        # this command is also sent on macOS Sierra and we need to allow it or else the test will fail
        allowed_command = "security set-key-partition-list -S apple-tool:,apple: -k \"\" /my/special.keychain &> /dev/null"

        allow(File).to receive(:exist?).and_return(false)
        expect(File).to receive(:exist?).with('/my/special.keychain').and_return(true)
        expect(File).to receive(:exist?).with('item.path').and_return(true)

        allow(FastlaneCore::Helper).to receive(:backticks).with(allowed_command, print: FastlaneCore::Globals.verbose?)
        expect(FastlaneCore::Helper).to receive(:backticks).with(expected_command, print: FastlaneCore::Globals.verbose?)

        Match::Utils.import('item.path', '/my/special.keychain')
      end

      it 'shows a user error if the keychain path cannot be resolved' do
        allow(File).to receive(:exist?).and_return(false)

        expect do
          Match::Utils.import('item.path', '/my/special.keychain')
        end.to raise_error(/Could not locate the provided keychain/)
      end

      it "tries to find the macOS Sierra keychain too" do
        expected_command = "security import item.path -k '#{Dir.home}/Library/Keychains/login.keychain-db' -P '' -T /usr/bin/codesign -T /usr/bin/security &> /dev/null"

        # this command is also sent on macOS Sierra and we need to allow it or else the test will fail
        allowed_command = "security set-key-partition-list -S apple-tool:,apple: -k \"\" #{Dir.home}/Library/Keychains/login.keychain-db &> /dev/null"

        allow(File).to receive(:exist?).and_return(false)
        expect(File).to receive(:exist?).with("#{Dir.home}/Library/Keychains/login.keychain-db").and_return(true)
        expect(File).to receive(:exist?).with("item.path").and_return(true)

        allow(FastlaneCore::Helper).to receive(:backticks).with(allowed_command, print: FastlaneCore::Globals.verbose?)
        expect(FastlaneCore::Helper).to receive(:backticks).with(expected_command, print: FastlaneCore::Globals.verbose?)

        Match::Utils.import('item.path', "login.keychain")
      end
    end

    describe "fill_environment" do
      it "#environment_variable_name uses the correct env variable" do
        result = Match::Utils.environment_variable_name(app_identifier: "tools.fastlane.app", type: "appstore")
        expect(result).to eq("sigh_tools.fastlane.app_appstore")
      end

      it "#environment_variable_name_team_id uses the correct env variable" do
        result = Match::Utils.environment_variable_name_team_id(app_identifier: "tools.fastlane.app", type: "appstore")
        expect(result).to eq("sigh_tools.fastlane.app_appstore_team-id")
      end

      it "#environment_variable_name_profile_name uses the correct env variable" do
        result = Match::Utils.environment_variable_name_profile_name(app_identifier: "tools.fastlane.app", type: "appstore")
        expect(result).to eq("sigh_tools.fastlane.app_appstore_profile-name")
      end

      it "pre-fills the environment" do
        my_key = "my_test_key"
        uuid = "my_uuid"

        result = Match::Utils.fill_environment(my_key, uuid)
        expect(result).to eq(uuid)

        item = ENV.find { |k, v| v == uuid }
        expect(item[0]).to eq(my_key)
        expect(item[1]).to eq(uuid)
      end
    end

    describe "certificates manipulation" do
      it "loads a pcks12 from file" do
        fixture_p12 = "./spec/fixtures/match_self_signed.p12"
        p12 = Match::Utils.load_pkcs12_file(fixture_p12)

        expect(p12).to be_kind_of(OpenSSL::PKCS12)
        expect(p12.certificate).to be_kind_of(OpenSSL::X509::Certificate)
        expect(p12.key).to be_kind_of(OpenSSL::PKey::RSA)
      end
    end
  end
end
