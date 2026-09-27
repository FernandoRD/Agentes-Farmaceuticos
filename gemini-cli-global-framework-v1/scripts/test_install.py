"""Offline installer regression checks for Pharmaceutical Framework v1. Run with Python 3.10+."""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name('install.sh').resolve()
PAYLOAD = SCRIPT.parents[1] / 'payload'
PD_PAYLOAD = SCRIPT.parents[1] / 'optional' / 'pd-farmacotecnico-specialist' / 'payload'
VIS_PAYLOAD = SCRIPT.parents[1] / 'optional' / 'visitacao-medica-specialist' / 'payload'


class InstallerTests(unittest.TestCase):
    def test_pd_farmacotecnico_specialist_is_opt_in(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'farmacia'
            base = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--apply'], capture_output=True, text=True)
            self.assertEqual(base.returncode, 0)
            
            tool_dir = None
            for p in (target / '.gemini', target / '.claude', target / '.cursor'):
                if p.exists():
                    tool_dir = p
                    break
            self.assertIsNotNone(tool_dir, 'Tool dot-directory must exist')
            specialist = tool_dir / 'skills' / 'pd-farmacotecnico-specialist' / 'SKILL.md'
            self.assertFalse(specialist.exists(), 'Specialist must be opt-in')

            audit = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-pd-farmacotecnico-specialist'], capture_output=True, text=True)
            self.assertEqual(audit.returncode, 0)
            self.assertFalse(specialist.exists(), 'Audit must not write')

            install = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-pd-farmacotecnico-specialist', '--apply'], capture_output=True, text=True)
            self.assertEqual(install.returncode, 0)
            self.assertTrue(specialist.exists(), 'Specialist must be installed when requested with --apply')

    def test_visitacao_medica_specialist_is_opt_in(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'farmacia'
            base = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--apply'], capture_output=True, text=True)
            self.assertEqual(base.returncode, 0)

            tool_dir = None
            for p in (target / '.gemini', target / '.claude', target / '.cursor'):
                if p.exists():
                    tool_dir = p
                    break
            self.assertIsNotNone(tool_dir)
            specialist = tool_dir / 'skills' / 'visitacao-medica-specialist' / 'SKILL.md'
            self.assertFalse(specialist.exists())

            install = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-visitacao-medica-specialist', '--apply'], capture_output=True, text=True)
            self.assertEqual(install.returncode, 0)
            self.assertTrue(specialist.exists())

    def test_with_all_specialists(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'farmacia_all'
            res = subprocess.run(['bash', str(SCRIPT), '--target', str(target), '--with-all-specialists', '--apply'], capture_output=True, text=True)
            self.assertEqual(res.returncode, 0)

            tool_dir = None
            for p in (target / '.gemini', target / '.claude', target / '.cursor'):
                if p.exists():
                    tool_dir = p
                    break
            self.assertIsNotNone(tool_dir)
            specs = ["pd-farmacotecnico-specialist", "visitacao-medica-specialist"]
            for s in specs:
                skill_file = tool_dir / 'skills' / s / 'SKILL.md'
                self.assertTrue(skill_file.exists(), f"Skill {s} missing with --with-all-specialists")

    def test_install_preserves_existing_data(self):
        with tempfile.TemporaryDirectory() as temporary:
            target = Path(temporary) / 'farmacia'

            def run(*extra):
                return subprocess.run(
                    ['bash', str(SCRIPT), '--target', str(target), *extra],
                    capture_output=True, text=True)

            self.assertEqual(run().returncode, 0)
            self.assertFalse(target.exists(), 'Audit must not create the target')
            self.assertEqual(run('--apply').returncode, 0)
            sources = [p for p in PAYLOAD.rglob('*') if p.is_file()]
            for source in sources:
                self.assertEqual((target / source.relative_to(PAYLOAD)).read_bytes(), source.read_bytes())
            self.assertEqual(run('--apply').returncode, 0)
            changed = target / sources[0].relative_to(PAYLOAD)
            changed.write_text('conteúdo de usuário', encoding='utf-8')
            
            missing = target / sources[1].relative_to(PAYLOAD)
            missing.unlink()
            self.assertEqual(run('--apply').returncode, 1, 'Must reject write on preflight conflict')
            self.assertEqual(changed.read_text(encoding='utf-8'), 'conteúdo de usuário')
            self.assertFalse(missing.exists())

    def test_rejects_link_target(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            outside = base / 'outside'
            outside.mkdir()
            link = base / 'link'
            try:
                link.symlink_to(outside, target_is_directory=True)
            except OSError:
                self.skipTest('Symlink creation unavailable on this host')
            result = subprocess.run(
                ['bash', str(SCRIPT), '--target', str(link), '--apply'],
                capture_output=True, text=True)
            self.assertEqual(result.returncode, 1)
            self.assertEqual(list(outside.iterdir()), [])

    def test_shell_scripts_exist(self):
        scripts_dir = SCRIPT.parent
        self.assertTrue((scripts_dir / 'install.sh').is_file())
        self.assertTrue((scripts_dir / 'install.fish').is_file())
        self.assertTrue((scripts_dir / 'install.ps1').is_file())


if __name__ == '__main__':
    unittest.main()
