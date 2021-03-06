require 'spec_helper'

describe 'arrow_alignment' do
  let(:msg) { 'indentation of => is not properly aligned' }

  context 'with fix disabled' do
    context 'selectors inside a resource' do
      let(:code) { "
        file { 'foo':
          ensure  => $ensure,
          require => $ensure ? {
            present => Class['tomcat::install'],
            absent  => undef;
          },
          foo     => bar,
        }"
      }

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'selectors in the middle of a resource' do
      let(:code) { "
        file { 'foo':
          ensure => $ensure ? {
            present => directory,
            absent  => undef,
          },
          owner  => 'tomcat6',
        }"
      }

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'selector inside a resource' do
      let(:code) { "
      ensure => $ensure ? {
        present => directory,
        absent  => undef,
      },
      owner  => 'foo4',
      group  => 'foo4',
      mode   => '0755'," }

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'selector inside a hash inside a resource' do
      let(:code) { "
      server => {
        ensure => ensure => $ensure ? {
          present => directory,
          absent  => undef,
        },
        ip     => '192.168.1.1'
      },
      owner  => 'foo4',
      group  => 'foo4',
      mode   => '0755'," }

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'nested hashes with correct indentation' do
      let(:code) { "
        class { 'lvs::base':
          virtualeservers => {
            '192.168.2.13' => {
              vport        => '11025',
              service      => 'smtp',
              scheduler    => 'wlc',
              protocol     => 'tcp',
              checktype    => 'external',
              checkcommand => '/path/to/checkscript',
              real_servers => {
                'server01' => {
                  real_server => '192.168.2.14',
                  real_port   => '25',
                  forwarding  => 'masq',
                },
                'server02' => {
                  real_server => '192.168.2.15',
                  real_port   => '25',
                  forwarding  => 'masq',
                }
              }
            }
          }
        }"
      }

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'single resource with a misaligned =>' do
      let(:code) { "
        file { '/tmp/foo':
          foo => 1,
          bar => 2,
          gronk => 3,
          baz  => 4,
          meh => 5,
        }"
      }

      it 'should detect four problems' do
        expect(problems).to have(4).problems
      end

      it 'should create four warnings' do
        expect(problems).to contain_warning(msg).on_line(3).in_column(15)
        expect(problems).to contain_warning(msg).on_line(4).in_column(15)
        expect(problems).to contain_warning(msg).on_line(6).in_column(16)
        expect(problems).to contain_warning(msg).on_line(7).in_column(15)
      end
    end

    context 'complex resource with a misaligned =>' do
      let(:code) { "
        file { '/tmp/foo':
          foo => 1,
          bar  => $baz ? {
            gronk => 2,
            meh => 3,
          },
          meep => 4,
          bah => 5,
        }"
      }

      it 'should detect three problems' do
        expect(problems).to have(3).problems
      end

      it 'should create three warnings' do
        expect(problems).to contain_warning(msg).on_line(3).in_column(15)
        expect(problems).to contain_warning(msg).on_line(6).in_column(17)
        expect(problems).to contain_warning(msg).on_line(9).in_column(15)
      end
    end

    context 'multi-resource with a misaligned =>' do
      let(:code) { "
        file {
          '/tmp/foo': ;
          '/tmp/bar':
            foo => 'bar';
          '/tmp/baz':
            gronk => 'bah',
            meh => 'no'
        }"
      }

      it 'should only detect a single problem' do
        expect(problems).to have(1).problem
      end

      it 'should create a warning' do
        expect(problems).to contain_warning(msg).on_line(8).in_column(17)
      end
    end

    context 'multiple single line resources' do
      let(:code) { "
        file { 'foo': ensure => file }
        package { 'bar': ensure => present }"
      }

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'resource with unaligned => in commented line' do
      let(:code) { "
        file { 'foo':
          ensure => directory,
          # purge => true,
        }"
      }

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'single line resource spread out on multiple lines' do
      let(:code) {"
        file {
          'foo': ensure => present,
        }"
      }

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'multiline resource with a single line of params' do
      let(:code) { "
        mymodule::do_thing { 'some thing':
          whatever => { foo => 'bar', one => 'two' },
        }"
      }

      it 'should not detect any problems' do
        expect(problems).to have(0).problems
      end
    end

    context 'resource with aligned => too far out' do
      let(:code) { "
        file { '/tmp/foo':
          ensure  => file,
          mode    => '0444',
        }"
      }

      it 'should detect 2 problems' do
        expect(problems).to have(2).problems
      end

      it 'should create 2 warnings' do
        expect(problems).to contain_warning(msg).on_line(3).in_column(19)
        expect(problems).to contain_warning(msg).on_line(4).in_column(19)
      end
    end
  end

  context 'with fix enabled' do
    before do
      PuppetLint.configuration.fix = true
    end

    after do
      PuppetLint.configuration.fix = false
    end

    context 'single resource with a misaligned =>' do
      let(:code) { "
        file { '/tmp/foo':
          foo => 1,
          bar => 2,
          gronk => 3,
          baz  => 4,
          meh => 5,
        }"
      }
      let(:fixed) { "
        file { '/tmp/foo':
          foo   => 1,
          bar   => 2,
          gronk => 3,
          baz   => 4,
          meh   => 5,
        }"
      }

      it 'should detect four problems' do
        expect(problems).to have(4).problems
      end

      it 'should fix the manifest' do
        expect(problems).to contain_fixed(msg).on_line(3).in_column(15)
        expect(problems).to contain_fixed(msg).on_line(4).in_column(15)
        expect(problems).to contain_fixed(msg).on_line(6).in_column(16)
        expect(problems).to contain_fixed(msg).on_line(7).in_column(15)
      end

      it 'should align the arrows' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'complex resource with a misaligned =>' do
      let(:code) { "
        file { '/tmp/foo':
          foo => 1,
          bar  => $baz ? {
            gronk => 2,
            meh => 3,
          },
          meep => 4,
          bah => 5,
        }"
      }
      let(:fixed) { "
        file { '/tmp/foo':
          foo  => 1,
          bar  => $baz ? {
            gronk => 2,
            meh   => 3,
          },
          meep => 4,
          bah  => 5,
        }"
      }

      it 'should detect three problems' do
        expect(problems).to have(3).problems
      end

      it 'should fix the manifest' do
        expect(problems).to contain_fixed(msg).on_line(3).in_column(15)
        expect(problems).to contain_fixed(msg).on_line(6).in_column(17)
        expect(problems).to contain_fixed(msg).on_line(9).in_column(15)
      end

      it 'should align the arrows' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'multi-resource with a misaligned =>' do
      let(:code) { "
        file {
          '/tmp/foo': ;
          '/tmp/bar':
            foo => 'bar';
          '/tmp/baz':
            gronk => 'bah',
            meh => 'no'
        }"
      }
      let(:fixed) { "
        file {
          '/tmp/foo': ;
          '/tmp/bar':
            foo => 'bar';
          '/tmp/baz':
            gronk => 'bah',
            meh   => 'no'
        }"
      }

      it 'should only detect a single problem' do
        expect(problems).to have(1).problem
      end

      it 'should fix the manifest' do
        expect(problems).to contain_fixed(msg).on_line(8).in_column(17)
      end

      it 'should align the arrows' do
        expect(manifest).to eq(fixed)
      end
    end

    context 'resource with aligned => too far out' do
      let(:code) { "
        file { '/tmp/foo':
          ensure  => file,
          mode    => '0444',
        }"
      }

      let(:fixed) { "
        file { '/tmp/foo':
          ensure => file,
          mode   => '0444',
        }"
      }

      it 'should detect 2 problems' do
        expect(problems).to have(2).problems
      end

      it 'should create 2 warnings' do
        expect(problems).to contain_fixed(msg).on_line(3).in_column(19)
        expect(problems).to contain_fixed(msg).on_line(4).in_column(19)
      end

      it 'should realign the arrows with the minimum whitespace' do
        expect(manifest).to eq(fixed)
      end
    end
  end
end
